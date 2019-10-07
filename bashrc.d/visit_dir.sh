
visit() {
  if [[ -z "$1" ]]; then
    echo "Sets a visit directory context. Usage: visit [path]"
  fi
  if [[ ! -d $1 ]]; then
    echo "Error: $1 is not a valid directory"
    return 1
  fi
  abs=$(python -c 'import sys, os; print(os.path.abspath(sys.argv[1]))' $1)
  echo $abs > ~/.visit
  export VISIT=$abs
}

cdv() {
  if [[ -z "$(cat ~/.visit)" ]]; then
    echo "Error: No visit"
    return 1
  fi
  cd $(cat ~/.visit)
}

if [[ ! -f ~/.visit ]]; then
  echo "" > ~/.visit
fi
export VISIT=$(cat ~/.visit)
