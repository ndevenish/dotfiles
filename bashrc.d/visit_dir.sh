
visit() {
  if [[ -z "$1" ]]; then
    echo "Sets a visit directory context. Usage: visit [path]"
  fi
  if [[ ! -d $1 ]]; then
    echo "Error: $1 is not a valid directory"
    return 1
  fi
  abs=$(python -c 'import sys, os; print(os.path.abspath(sys.argv[1]))' $1)
  echo "$(date -Iseconds) $abs" >> ~/.visit
  export VISIT=$abs
}

cdv() {
  if [[ -z "$(_read_visit)" ]]; then
    echo "Error: No visit"
    return 1
  fi
  cd $(_read_visit)
}

_read_visit() {
  cat ~/.visit | tail -n 1 | cut -d' ' -f 2-
}

if [[ ! -f ~/.visit ]]; then
  echo "" > ~/.visit
fi
export VISIT=$(_read_visit)
