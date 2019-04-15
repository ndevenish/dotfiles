remove_temps() {
  if [[ -f ~/.temporary_test_dirs ]]; then
    for test in $(cat ~/.temporary_test_dirs); do
      if [[ "$(pwd)" == "$test" ]]; then
        echo "Not removing current directory"
        PRESERVE=$test
      else
        if [[ -d $test ]]; then
          echo "Removing $test"
          rm --preserve-root -rfI $test
        fi
      fi
    done
    rm ~/.temporary_test_dirs
    if [[ -n "$PRESERVE" ]]; then
      echo "$PRESERVE" >> ~/.temporary_test_dirs
    fi
  fi
}

mktmp() {
  cd $(mktemp --tmpdir=/dls/tmp/mep23677 -d)
  echo $(pwd) $(date -u +"%Y-%m-%dT%H:%M:%S") >> ~/.temporary_test_dirs
}

cdtmp() {
  # Have we been passed an integer line?
  if [[ $1 =~ ^-?[0-9]+$ ]]; then
    # We've been passed an integer temporary number
    N=$(($1+1))
  elif [[ -n "$1" ]]; then
    # Passed something not a number - a whole name?
    # Work out which line (from the end of the file) has this string
    echo "Named folders not yet implemented"
    return
  else
    mktmp
    return
  fi
  # Extract the desired line
  last_temp=$(tail -n $N ~/.temporary_test_dirs | head -n 1 | awk '{ print $1 }')
  if [[ -z $last_temp ]]; then
    echo "Could not read log of temporary dirs"
    return
  else
    if [[ ! -d $last_temp ]]; then
      echo "Could not find $last_temp"
    else
      cd $last_temp
    fi
  fi
}

########################################################################
# Get or set the name of a current temporary directory
#
# Usage: name [-d || <NAME>]
#
# Options:
#     -d      The name will be removed instead of set
#
# Arguments:
#     <NAME>  The new name to set for the current folder
#
# The current directory must be listed in the temporary folder
# file. Setting a name will also set up a .preserve file, for
# filesystems that are regularly cleaned.
########################################################################
name() {
  line=$(grep -e "^$(pwd)" ~/.temporary_test_dirs)
  if [[ -z "$line" ]]; then
    echo "Error: Not in listed temporary folder"
    return 1
  fi
  if [[ "$1" == "-d" ]]; then
    # Delete the name
    newline=$(echo "$line" | awk '{ print $1 " " $2; }')
    sed -ib -e "s;^$line;$newline;" ~/.temporary_test_dirs
    rm -f .preserve
  elif [[ -n "$1" ]]; then
    # Rewrite the name
    newline=$(echo "$line" | awk '{ print $1 " " $2; }')
    sed -ib -e "s;^$line;$newline $1;" ~/.temporary_test_dirs
    touch .preserve
  else
    # Print the name
    name=$(echo "$line" | awk '{ print $3; }')
    if [[ -z "$name" ]]; then
      return 2
    fi
    touch .preserve
    echo "$name"
  fi
}

cdltmp() {
  cdtmp 0
}

lstmp() {
  # Short python program to parse and format nicely
  python - <<'EOF'
import os
data = [x.strip().split() for x in open(os.path.expanduser("~/.temporary_test_dirs")).readlines()]
data = [x + [None, "", ""][len(x):] for x in data]
lens = map(lambda x: max(len(y) for y in x), zip(*data))
for i, (dir, dat, nam) in zip(reversed(range(len(data))), data):
  if not os.path.isdir(dir):
    continue
  print " ".join(["\033[1;31m{0:2d}\033[0m".format(i),
                "\033[1;32m"+nam.ljust(lens[2])+"\033[0m",
                dat.ljust(lens[1]),
                "\033[37m"+dir.ljust(lens[0])+"\033[0m"])
EOF
}

