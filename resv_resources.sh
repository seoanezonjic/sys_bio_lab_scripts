#! /usr/bin/env bash


# Default variable values
preset="none"
cores=5
mem="80gb"
time="7-00:00:00"
constraint="cal"

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help        Display this help message"
 echo " -p, --preset      Resource preset. This overrides all other options."
 echo "                     \"high\": 42 cores, 500gb RAM"
 echo "                     \"low\": 5 cores, 80 gb RAM"
 echo " -c, --cores       Number of cores to request. Format: --cores 42. Default 5 cores."
 echo " -m, --mem         RAM to request. Format: --mem 500gb. Default 80gb."
 echo " -t, --time        Time to request interactive node. Format d-hh:mm:ss. Default: 7 days."
 echo " -n, --constraint  Slurm queue where jobs will be launched. Default: cal."

}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -p | --preset*)
        if ! has_argument $@; then
          echo "Missing argument for preset flag." >&2
          usage
          exit 1
        fi

        valid_presets="high\nlow"
        preset=$(extract_argument $@)
        preset=${preset^^}
        matches=`echo -e $valid_presets | grep -w -c $preset`

        if [ $matches != 1 ]; then
          echo "Unrecognised option for preset argument. Must be \"high\" or \"low\". Was \"$preset\"."
          exit 1
        fi

        shift
        ;;

      -m | --mem*)
        if ! has_argument $@; then
          echo "Missing argument for mem flag." >&2
          usage
          exit 1
        fi

        mem=$(extract_argument $@)

        shift
        ;;

      -c | --cores*)
        if ! has_argument $@; then
          echo "Missing argument for cores flag." >&2
          usage
          exit 1
        fi

        cores=$(extract_argument $@)

        shift
        ;;
      -t | --time*)
        if ! has_argument $@; then
          echo "\"time\" flag requires an argument." >&2
          usage
          exit 1
        fi

        time=$(extract_argument $@)

        shift
        ;;

      -n | --constraint*)
        if ! has_argument $@; then
          echo "Constraint flag requires argument." >&2
          usage
          exit 1
        fi

        valid_constraints="cal\nbc\nsr\noHT\namd\nbigmem\ndgx\na100\ndownload\nintel"
        constraint=$(extract_argument $@)
        constraint=${constraint,,}
        matches=`echo -e $valid_constraints | grep -w -c $constraint`

        if [ $matches != 1 ]; then
          echo "Unrecognised option for constraint argument. Must be one of ${valid_constraints//$'\\n'/', '}. Was \"$constraint\"."
          exit 1
        fi

        shift
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

handle_options "$@"

if [ "$preset" == "high" ]; then
  cores=42
  mem=500gb
  time=7-00:00:00
  constraint=cal
elif [ "$preset" == "low" ]; then
	cores=5
  mem=80gb
  time=7-00:00:00
  constraint=cal
fi

command="salloc --cpus-per-task $cores --mem $mem --time $time --constraint $constraint"

echo "Command called: $command"
$command
