#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
parse_slurm_logs.py
-------------------
Carga uno o varios archivos .tar con logs de `scontrol show node` (un .log por
instantánea, nombrado AAAA_MM_DD_hh_mm_ss.log), los parsea y deja TODO en una
única tabla de pandas: la variable `df` (una fila = un nodo en una instantánea).

Uso:
    python parse_slurm_logs.py -i piclogs.tar
    python parse_slurm_logs.py -i a.tar,b.tar
    python parse_slurm_logs.py -i "logs/*.tar"          # glob (entre comillas)
    python parse_slurm_logs.py -i a.tar "logs/*.tar" -o tabla.csv

Columnas añadidas respecto al log original:
    source_tar, source_file          origen de la fila
    timestamp                        datetime tomado del nombre del .log
    anio, mes, dia, hora, minuto, segundo
    state_base                       estado principal (MIXED, IDLE, DOWN...)
    state_flags                      resto de estados unidos por '+' (RESERVED, DRAIN...)
    state_suffix                     símbolos finales de Slurm (*, ~, #...)
    state_tokens                     todos los estados limpios, p.ej. MIXED+RESERVED
    cfg_cpu, cfg_mem_mb, cfg_billing, cfg_gpu      (de CfgTRES)
    alloc_cpu, alloc_mem_mb, alloc_gpu             (de AllocTRES)
    cpu_alloc_pct, mem_alloc_pct, cpu_idle

La última línea del script deja la tabla en `df`, lista para usar.
"""
import argparse
import glob
import os
import re
import sys
import tarfile
from datetime import datetime

import numpy as np
import pandas as pd

from py_report_html.py_report_html import Py_report_html

# -------------------------------------------------------------------------- #
# Definicion de funciones
# -------------------------------------------------------------------------- #

def expand_inputs(items):
    """Admite rutas sueltas, listas separadas por comas y comodines (glob)."""
    paths = []
    for item in items:
        for part in item.split(","):
            part = os.path.expanduser(part.strip())
            if not part:
                continue
            matches = sorted(glob.glob(part))
            if not matches:
                print(f"[aviso] sin coincidencias para: {part}", file=sys.stderr)
            paths.extend(matches)
    seen, unique = set(), []
    for p in paths:
        if p not in seen:
            seen.add(p)
            unique.append(p)
    return unique

# Nº de dígitos del epoch -> divisor para pasarlo a segundos (10=s, 13=ms, 16=µs, 19=ns)
EPOCH_DIVISOR = {10: 1, 13: 1_000, 16: 1_000_000, 19: 1_000_000_000}
def timestamp_from_name(name):
    """Fecha de un log a partir de su nombre.

    Acepta el epoch de bash (p. ej. 1761820490123 o 1761820490123.log, de `date +%s%3N`) y,
    por compatibilidad, el formato antiguo AAAA_MM_DD_hh_mm_ss. El epoch se convierte a la
    hora local de la máquina, igual que hacía antes `date +%Y_%m_%d_%H_%M_%S`.
    """
    stem = os.path.splitext(name)[0]
    if stem.isdigit() and len(stem) in EPOCH_DIVISOR:
        return datetime.fromtimestamp(int(stem) / EPOCH_DIVISOR[len(stem)])
    m = FILENAME_RE.search(name)
    if not m:
        return None
    return datetime(*map(int, m.groups()))


def iter_dir_logs(dir_path):
    """Itera (nombre_log, timestamp, texto) de los logs sueltos dentro de una carpeta."""
    skipped = 0
    for entry in sorted(os.scandir(dir_path), key=lambda e: e.name):
        if not entry.is_file():
            continue
        ts = timestamp_from_name(entry.name)
        if ts is None:  # no es un log (p. ej. un piclogs.tar que quede en la carpeta)
            skipped += 1
            continue
        if not in_range(ts):  # se descarta antes de abrir el archivo
            continue
        with open(entry.path, "r", encoding="utf-8", errors="replace") as fh:
            yield entry.name, ts, fh.read()
    if skipped:
        print(f"[aviso] {dir_path}: {skipped} archivos sin fecha en el nombre, omitidos", file=sys.stderr)


def parse_snapshot(text):
    """Convierte la salida de `scontrol show node` en una lista de dicts (uno por nodo)."""
    nodes, current = [], None
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        for key, value in KV_RE.findall(line):
            value = value.strip()
            if key == "NodeName":
                current = {}
                nodes.append(current)
            if current is not None:
                current[key] = value
    return nodes


def split_state(raw):
    """'MIXED+RESERVED*' -> (base, flags, suffix, tokens)."""
    if not isinstance(raw, str) or not raw.strip():
        return ("UNKNOWN", "", "", "UNKNOWN")
    tokens, suffix = [], ""
    for tok in raw.split("+"):
        clean = tok.rstrip(STATE_SYMBOLS)
        suffix += tok[len(clean):]
        if clean:
            tokens.append(clean.upper())
    if not tokens:
        return ("UNKNOWN", "", suffix, "UNKNOWN")
    return (tokens[0], "+".join(tokens[1:]), suffix, "+".join(tokens))


def parse_tres(value):
    """'cpu=128,mem=450000M,gres/gpu=4' -> dict."""
    out = {}
    if isinstance(value, str):
        for item in value.split(","):
            if "=" in item:
                k, v = item.split("=", 1)
                out[k.strip()] = v.strip()
    return out


def mem_to_mb(value):
    """'300G' -> 307200 (MB). Sin sufijo se interpreta como MB."""
    if value is None:
        return np.nan
    m = re.fullmatch(r"(\d+(?:\.\d+)?)([KMGTP]?)", str(value).strip(), flags=re.I)
    if not m:
        return np.nan
    num, unit = float(m.group(1)), m.group(2).upper()
    factor = {"K": 1 / 1024, "": 1, "M": 1, "G": 1024, "T": 1024 ** 2, "P": 1024 ** 3}[unit]
    return num * factor

def parse_date_bound(text, name):
    """Devuelve (inicio, fin_exclusivo) del periodo que describe el texto."""
    text = text.strip()
    for rx, fmt, step in _DATE_PATTERNS:
        if re.fullmatch(rx, text):
            try:
                start = pd.Timestamp(datetime.strptime(text, fmt))
            except ValueError:
                break
            return start, start + step
    sys.exit(f"Formato no válido en {name}: '{text}'. Usa AAAA, AAAA-MM, AAAA-MM-DD, "
             f"AAAA-MM-DD-HH o AAAA-MM-DD-HH:MM")


def in_range(ts):
    if DATE_FROM is not None and ts < DATE_FROM:
        return False
    if DATE_TO is not None and ts >= DATE_TO:
        return False
    return True

# --------------------------------------------------------------------------- #
# Argumentos
# --------------------------------------------------------------------------- #
parser = argparse.ArgumentParser(description="Carga logs de 'scontrol show node' desde archivos tar.")
parser.add_argument(
    "-i", "--input", nargs="+", required=True,
    help="Una o varias carpetas con logs sueltos. Admite varios argumentos, "
         "listas separadas por comas y comodines (glob) como 'logs/sub*/'.",
)
parser.add_argument(
    "-o", "--output", dest="output_report", default=None,
    help="(Opcional) guarda además la tabla en .csv, .parquet o .pkl según la extensión.",
)
parser.add_argument(
    "-t", "--template", dest="template", default=None,
    help="(Opcional) ruta a un template de Mako para generar un informe HTML. ",
)
parser.add_argument(
    "--date_start", default=None,
    help="Solo registros desde esta fecha (incluida). Resolución incremental: AAAA, AAAA-MM, "
         "AAAA-MM-DD, AAAA-MM-DD-HH o AAAA-MM-DD-HH:MM.",
)
parser.add_argument(
    "--date_end", default=None,
    help="Solo registros hasta esta fecha (el periodo indicado se incluye entero: '2022-05' llega "
         "hasta el 31 de mayo, '2025' hasta el 31 de diciembre). Mismos formatos que --date_start.",
)
args, _unknown = parser.parse_known_args()

# --------------------------------------------------------------------------- #
# Utilidades
# --------------------------------------------------------------------------- #
FILENAME_RE = re.compile(r"(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})")
# clave=valor; el valor llega hasta la siguiente clave o el final de la línea
# (así se soportan valores con espacios como OS=Linux ... o Reason=...)
KV_RE = re.compile(r"(?<!\S)([A-Za-z_][\w.]*)=(.*?)(?=\s+[A-Za-z_][\w.]*=|\s*$)")
STATE_SYMBOLS = "*~#!%$@^-"

NUMERIC_COLS = [
    "CoresPerSocket", "CPUAlloc", "CPUEfctv", "CPUTot", "CPULoad", "RealMemory",
    "AllocMem", "FreeMem", "Sockets", "Boards", "ThreadsPerCore", "TmpDisk",
    "Weight", "CurrentWatts", "AveWatts",
]
DATETIME_COLS = ["BootTime", "SlurmdStartTime", "LastBusyTime", "ResumeAfterTime"]


# --------------------------------------------------------------------------- #
# Carga
# --------------------------------------------------------------------------- #
# Filtro de fechas: la resolución la marca el nº de componentes que se indiquen
_DATE_PATTERNS = [
    (r"\d{4}", "%Y", pd.DateOffset(years=1)),
    (r"\d{4}-\d{2}", "%Y-%m", pd.DateOffset(months=1)),
    (r"\d{4}-\d{2}-\d{2}", "%Y-%m-%d", pd.DateOffset(days=1)),
    (r"\d{4}-\d{2}-\d{2}-\d{2}", "%Y-%m-%d-%H", pd.DateOffset(hours=1)),
    (r"\d{4}-\d{2}-\d{2}-\d{2}:\d{2}", "%Y-%m-%d-%H:%M", pd.DateOffset(minutes=1)),
]

DATE_FROM = parse_date_bound(args.date_start, "--date_start")[0] if args.date_start else None
DATE_TO = parse_date_bound(args.date_end, "--date_end")[1] if args.date_end else None  # exclusivo
if DATE_FROM is not None and DATE_TO is not None and DATE_FROM >= DATE_TO:
    sys.exit("--date_start debe ser anterior a --date_end")

file_paths = expand_inputs(args.input)
if not file_paths:
    sys.exit("No se ha encontrado ninguna carpeta con los patrones indicados.")

records = []
for src_path in file_paths:
    n_logs = 0
    # carpeta con logs sueltos o archivo tar
    source = iter_dir_logs(src_path)
    for log_name, ts, text in source:
        n_logs += 1
        for node in parse_snapshot(text):
            node["source_tar"] = os.path.basename(os.path.normpath(src_path))
            node["source_file"] = log_name
            node["timestamp"] = ts
            records.append(node)
    print(f"[ok] {src_path}: {n_logs} logs", file=sys.stderr)

if not records:
    sys.exit("No se ha podido parsear ningún nodo.")

df = pd.DataFrame.from_records(records)

# --------------------------------------------------------------------------- #
# Limpieza y variables derivadas
# --------------------------------------------------------------------------- #
obj_cols = df.select_dtypes(include="object").columns
df[obj_cols] = df[obj_cols].replace({"(null)": np.nan})

# Si el mismo log está en varios tar, nos quedamos con una sola copia
df = df.drop_duplicates(subset=["timestamp", "NodeName"], keep="last")

# Variables de tiempo
df["timestamp"] = pd.to_datetime(df["timestamp"])
df["anio"] = df["timestamp"].dt.year
df["mes"] = df["timestamp"].dt.month
df["dia"] = df["timestamp"].dt.day
df["hora"] = df["timestamp"].dt.hour
df["minuto"] = df["timestamp"].dt.minute
df["segundo"] = df["timestamp"].dt.second

# Numéricas y fechas (si un log no trae alguna columna, se crea vacía para que
# la plantilla no falle)
for col in NUMERIC_COLS:
    if col not in df:
        df[col] = np.nan
    df[col] = pd.to_numeric(df[col], errors="coerce")
for col in DATETIME_COLS:
    if col in df:
        df[col] = pd.to_datetime(df[col], format="%Y-%m-%dT%H:%M:%S", errors="coerce")

# Estado
if "State" not in df:
    df["State"] = np.nan
state_parts = df["State"].apply(split_state)
df["state_base"] = state_parts.str[0]
df["state_flags"] = state_parts.str[1]
df["state_suffix"] = state_parts.str[2]
df["state_tokens"] = state_parts.str[3]

# TRES (recursos configurados y asignados)
cfg = df["CfgTRES"].apply(parse_tres) if "CfgTRES" in df else pd.Series([{}] * len(df), index=df.index)
alc = df["AllocTRES"].apply(parse_tres) if "AllocTRES" in df else pd.Series([{}] * len(df), index=df.index)
df["cfg_cpu"] = pd.to_numeric(cfg.apply(lambda t: t.get("cpu")), errors="coerce")
df["cfg_mem_mb"] = cfg.apply(lambda t: mem_to_mb(t.get("mem")))
df["cfg_billing"] = pd.to_numeric(cfg.apply(lambda t: t.get("billing")), errors="coerce")
df["cfg_gpu"] = pd.to_numeric(cfg.apply(lambda t: t.get("gres/gpu")), errors="coerce")
df["alloc_cpu"] = pd.to_numeric(alc.apply(lambda t: t.get("cpu")), errors="coerce")
df["alloc_mem_mb"] = alc.apply(lambda t: mem_to_mb(t.get("mem")))
df["alloc_gpu"] = pd.to_numeric(alc.apply(lambda t: t.get("gres/gpu")), errors="coerce")

# Métricas derivadas
df["cpu_alloc_pct"] = 100 * df["CPUAlloc"] / df["CPUEfctv"].where(df["CPUEfctv"] > 0)
df["mem_alloc_pct"] = 100 * df["AllocMem"] / df["RealMemory"].where(df["RealMemory"] > 0)
df["cpu_idle"] = (df["CPUEfctv"] - df["CPUAlloc"]).clip(lower=0)

# Orden de columnas: primero identificación y tiempo, luego el resto
front = [
    "source_tar", "source_file", "timestamp", "anio", "mes", "dia", "hora", "minuto", "segundo",
    "NodeName", "state_base", "state_flags", "state_suffix", "state_tokens",
]
front = [c for c in front if c in df]
df = df[front + [c for c in df.columns if c not in front]]
df = df.sort_values(["timestamp", "NodeName"]).reset_index(drop=True)

print(
    f"[ok] tabla lista: {len(df):,} filas | {df['timestamp'].nunique():,} instantáneas | "
    f"{df['NodeName'].nunique():,} nodos | {df['timestamp'].min()} -> {df['timestamp'].max()}",
    file=sys.stderr,
)

#if args.output:
#    ext = os.path.splitext(args.output)[1].lower()
#    if ext == ".csv":
#        df.to_csv(args.output, index=False)
#    elif ext == ".parquet":
#        df.to_parquet(args.output, index=False)
#    elif ext in (".pkl", ".pickle"):
#        df.to_pickle(args.output)
#    else:
#        print(f"[aviso] extensión '{ext}' no reconocida, no se guarda archivo", file=sys.stderr)

# `df` queda como variable final: es la tabla que consume la plantilla de Mako.
current_dir = os.path.dirname(os.path.abspath(__file__))
container = {"df": df}
template = open(args.template).read()
report = Py_report_html(container, os.path.basename(args.output_report), True)
report.data_from_files = False
report.build(template)
report.write(args.output_report)