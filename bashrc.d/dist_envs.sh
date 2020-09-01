

_dirdb() {
    print_help() { cat <<EOF
Usage: _dirdb FILE COMMAND [options]
  find (NAME|NUMBER)   Find an entry by name or reverse-index
  add PATH [NAME]      Add a path, with an optional name
  name PATH [NAME]     Name a path, or remove the name for a path
  list                 Print a nice table
EOF
}
    _positionals=()
    while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-h|--help)
				print_help
				return 0
				;;
			*)
				_positionals+=("$1")
				;;
		esac
		shift
	done
    set -- ${_positionals[@]} # restore positional parameters
    if [[ $# -lt 2 ]]; then
        print_help
        return 1
    fi
    SOURCE=$1
    COMMAND=$2
    shift 2
    if [[ ! -f "$SOURCE" ]]; then
        touch $SOURCE
    fi
    if [[ $COMMAND == "find" ]]; then
        # Have we been passed an integer line?
        if [[ $1 =~ ^-?[0-9]+$ ]]; then
            # We've been passed an integer temporary number
            N=$(($1+1))
            echo $(tail -n $N $SOURCE | head -n 1 | awk '{ print $1 }')
        elif [[ -n "$1" ]]; then
            # Passed something not a number - a whole name?
            # Work out which line (from the end of the file) has this string
            dirs=$(awk "\$3 == \"$1\"" $SOURCE)
            if [[ $(echo "$dirs" | wc -l) -gt 1 ]]; then
                echo "Error: More than one result matches" >&2
                return 1
            elif [[ -n "$dirs" ]]; then
                echo "$(echo "$dirs" | awk '{ print $1; }')"
            else
                echo "Error: Could not find entry '$1'" >&2
                return 1
            fi
        fi
        return 0
    elif [[ $COMMAND == "add" ]]; then
        if [[ -z "$1" ]]; then
            echo "Error: No path provided" >&2
            return 1
        fi
        if [[ -z "$2" ]]; then
            echo "$1 $(date -u +"%Y-%m-%dT%H:%M:%S")" >> $SOURCE
        else
            echo "$1 $(date -u +"%Y-%m-%dT%H:%M:%S") $2" >> $SOURCE
        fi
    elif [[ $COMMAND == "remove" ]]; then
        echo "Error: remove not implemented yet" >&2
        return 1
    elif [[ $COMMAND == "name" ]]; then
        if [[ $# -eq 0 ]]; then
            echo "Error: No path specified" >&2
            return 1
        fi
        line=$(grep -e "^$1" $SOURCE)
        newname=$2
        if [[ -z "$line" ]]; then
            echo "Error: Not in listed file" >&2
            return 1
        fi
        if [[ $# -lt 2 ]]; then
            # Delete the name
            newline=$(echo "$line" | awk '{ print $1 " " $2; }')
            sed -ib -e "s;^$line;$newline;" $SOURCE
        elif [[ -n "$1" ]]; then
            # Rewrite the name
            newline=$(echo "$line" | awk '{ print $1 " " $2; }')
            sed -ib -e "s;^$line;$newline $2;" $SOURCE
        fi
    elif [[ $COMMAND == "list" ]]; then
        # Short python program to parse and format nicely
        python - <<EOF
# coding: utf-8
import os
data = [x.strip().split() for x in open(os.path.expanduser("${SOURCE}")).readlines()]
data = [x + [None, "", ""][len(x):] for x in data]
lens = map(lambda x: max(len(y) for y in x), zip(*data))
for i, (dir, dat, nam) in zip(reversed(range(len(data))), data):
  if not os.path.isdir(dir):
    continue
  parts = ["\033[1;31m{0:2d}\033[0m".format(i)]
  parts.append("\033[1;32m"+nam.ljust(lens[2])+"\033[0m")
  parts.append(dat.ljust(lens[1]))
  parts.append("\033[37m"+dir.ljust(lens[0])+"\033[0m")
  print (" ".join(parts))
EOF
    else
        echo "ERROR: _dirdb does not recognise command \"$COMMAND\""
        return 1
    fi
}

_dist_envs_print_help() {
    cat <<EOF
Usage: dist [options]
       dist [options] add [--name NAME] PATH
       dist [options] remove (NAME|NUMBER|PATH)
       dist [options] last
       dist [options] (NAME|NUMBER|PATH)

Print a list of valid distributions, add a path (with optional name),
activate the last used distribution, or activate by name/number.
Activating via path will add the path to the active distribution list.

Options:
    -h, --help  Show this message
    --name      Specify a name to add or remove
EOF
}

# Location of the dists path store
DIST_PATH=~/.dists

dist() {

    NAME=""
    # Parse any command options
    _positionals=()
    while test $# -gt 0
    do
        _key="$1"
        case "$_key" in
            -n|--name)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                NAME="$2"
                shift
                ;;
            --name=*)
                NAME="${_key##--option=}"
                ;;
            -h|--help)
                _dist_envs_print_help
                return 0
                ;;
            -h*)
                _dist_envs_print_help
                return 0
                ;;
            *)
                _positionals+=("$1")
                ;;
        esac
        shift
    done
    set -- ${_positionals[@]}

    COMMAND=$1
    shift

    if [[ -z "$COMMAND" || "$COMMAND" == "list" ]]; then
        _dirdb $DIST_PATH list
    elif [[ "$COMMAND" == "add" ]]; then
        path=$1
        if [[ -z "$path" ]]; then
            path=$(pwd)
        fi
        _dirdb $DIST_PATH add $path $NAME
    elif [[ "$COMMAND" == "remove" ]]; then
        echo ""
    elif [[ "$COMMAND" == "last" ]]; then
        last_path=$(_dirdb $DIST_PATH find 0)
        activate_libtbx_dist $last_path
    else
        echo ""
    fi
}


activate_libtbx_dist() {
    if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: activate_libtbx_dist PATH"
        return 1
    fi
    SETUP_DIR=${1%/}
    echo "Setting up working directory ${SETUP_DIR}"
    if [[ ! -f $SETUP_DIR/setup.sh && ! -f $SETUP_DIR/setpaths.sh ]]; then
        echo "Could not find setup script setup.sh or setpaths.sh"
        return 1
    fi
    # Add the base install to the active PATH
    # Doing this *might* cause conflicts
    if [[ -d $SETUP_DIR/../conda_base ]]; then
        # export PATH=$SETUP_DIR/../conda_base/bin:$PATH
        conda activate $SETUP_DIR/../conda_base
        export _DIST_REMOVE_PATH=$SETUP_DIR/../conda_base/bin
    elif [[ -d $SETUP_DIR/../base ]]; then
        export PATH=$SETUP_DIR/../base/bin:$PATH
        export _DIST_REMOVE_PATH=$SETUP_DIR/../base/bin
    fi
    if [[ -d $SETUP_DIR/../base/Python.framework/Versions/Current/bin ]]; then
        export PATH=$SETUP_DIR/../base/Python.framework/Versions/Current/bin:$PATH
        export _DIST_REMOVE_PATH=$SETUP_DIR/../base/Python.framework/Versions/Current/bin:$_DIST_REMOVE_PATH
    fi
    # If a setup.sh present, use that as a priority
    if [[ -f $SETUP_DIR/setup.sh ]]; then
        OLD_DIR=$(pwd)
        cd $SETUP_DIR
        source $SETUP_DIR/setup.sh
        cd $OLD_DIR
    elif [[ -f $SETUP_DIR/setpaths.sh && -z "$(grep "DIALS environment has changed" "${SETUP_DIR}/setpaths.sh")" ]]; then
        source $SETUP_DIR/setpaths.sh
    else
        export PATH="${SETUP_DIR}/bin:${PATH}"
    fi
    echo $SETUP_DIR > ~/.last_dials
    export DIALS_DIST=${SETUP_DIR}
}


setup_this() {
    dist add $(pwd)
    activate_libtbx_dist $(pwd)
}

r() {
    activate_libtbx_dist $(cat ~/.last_dials)
}

_find_dials_build() {
  if [[ -n "${DIALS_DIST}" ]]; then
    echo ${DIALS_DIST}
  else
    # Try to find it via other means
    if command -v libtbx.show_build_path 2>&1 >/dev/null; then
      libtbx.show_build_path
    fi
  fi
}

cdd() {
  build=$(_find_dials_build)
  if [[ -z "${build}" ]]; then
    echo "No dials distribution active"
    return 1
  else
    cd ${build}
  fi
}

dmake() {
  build=$(_find_dials_build)
  if [[ -z "${build}" ]]; then
    echo "No dials distribution active"
    return 1
  else
    ( cd ${build}
      make
    )
  fi
}

cdm() {
  if [[ -z "${DIALS_DIST}" ]]; then
    echo "No dials distribution active"
  else
    cd ${DIALS_DIST}/../modules
  fi
}
