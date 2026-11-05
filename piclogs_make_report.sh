#!/usr/bin/env bash

# 1. Definir función de ayuda
show_help() {
    echo "Uso: piclogs_make_report.sh [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -s, --date_start FECHA     Fecha de inicio (e.g., AAAA, AAAA-MM, AAAA-MM-DD, AAAA-MM-DD-HH, AAAA-MM-DD-HH:MM). Opcional."
    echo "  -e, --date_end FECHA       Fecha de fin (formato igual al de date_start). Opcional."
    echo "  -o, --output_file ARCHIVO  Ruta para el archivo HTML de salida. Opcional (por defecto: ~pedro/piclogs/reports/AAAA_MM_DD_report.html)."
    echo "  -h, --help                 Muestra este mensaje de ayuda y termina."
    echo ""
    echo "Ejemplo:"
    echo "  piclogs_make_report.sh -s 2026-10 -e 2026-11 -o ./mi_reporte.html"
    exit 0
}

# 2. Inicializar variables de flags vacías por defecto
date_start=""
date_end=""
output_file=""

# 3. Procesar los argumentos de Bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--date_start) date_start="$2"; shift ;;
        -e|--date_end) date_end="$2"; shift ;;
        -o|--output_file) output_file="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo "Error: Parámetro desconocido '$1'. Usa -h o --help para ayuda."; exit 1 ;;
    esac
    shift
done

# 4. Inicializar entorno y directorios
source ~soft_bio_267/initializes/init_python 

SCRIPT_FILE=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_PATH=$(dirname "$SCRIPT_FILE")
aux_dir=$SCRIPT_PATH/piclogs_aux_files 

logs_dir=~pedro/piclogs 
reports_dir=$logs_dir/reports 
tar_DB_path="$logs_dir/piclogs.tar" 

# 5. Comportamiento por defecto para el output_file
if [[ -z "$output_file" ]]; then
    filename=$(date +"%Y_%m_%d")
    output_file="${reports_dir}/${filename}_report.html"
fi

# 6. Construir de forma dinámica los argumentos para Python usando un array
cmd_args=(
    "-i" "$tar_DB_path"
    "-o" "$output_file"
    "-t" "$aux_dir/template.txt"
)

# Añadir date_start si fue introducido
if [[ -n "$date_start" ]]; then
    cmd_args+=("--date_start" "$date_start")
fi

# Añadir date_end si fue introducido
if [[ -n "$date_end" ]]; then
    cmd_args+=("--date_end" "$date_end")
fi

# 7. Ejecutar el script de Python con el array expandido
$aux_dir/aux_get_report.py "${cmd_args[@]}"
