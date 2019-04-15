

setup_dials() {
  if [[ -z "$1" ]]; then
    SETUP_DIR=$(pwd)
    SETUP_DIR=${SETUP_DIR%/}
  else
    SETUP_DIR=${1%/}
  fi
  echo "Setting up working directory ${SETUP_DIR}"
  # If no setup script, don't do the setup
  if [[ ! -f $SETUP_DIR/setup.sh && ! -f $SETUP_DIR/setpaths.sh ]]; then
    echo "Could not find setup script setup.sh or setpaths.sh"
    return
  fi

  if [[ -f $SETUP_DIR/setup.sh ]]; then
    OLD_DIR=$(pwd)
    cd $SETUP_DIR
    source $SETUP_DIR/setup.sh
    cd $OLD_DIR
  elif [[ -f $SETUP_DIR/setpaths.sh  ]]; then
    source $SETUP_DIR/setpaths.sh
    export PATH=$SETUP_DIR/../base/bin:$PATH
  fi
  echo $SETUP_DIR > ~/.last_dials
  export DIALS_DIST=${SETUP_DIR}
}

setup_this() {
  setup_dials
}

r() {
  SETUP_DIR=$(cat ~/.last_dials)
  setup_dials ${SETUP_DIR}
}

_find_dials_build() {
  if [[ -n "${DIALS_DIST}" ]]; then
    echo ${DIALS_DIST}
  else
    # Try to find it via other means
    if command -v libtbx.show_build_path 2>&1 >/dev/null; then
      libtbx.show_build_path
    fi
  fi
}

cdd() {
  build=$(_find_dials_build)
  if [[ -z "${build}" ]]; then
    echo "No dials distribution active"
  else
    cd ${build}
  fi
}

cdm() {
  if [[ -z "${DIALS_DIST}" ]]; then
    echo "No dials distribution active"
  else
    cd ${DIALS_DIST}/../modules
  fi
}
im() {
  if [[ -z "${DIALS_DIST}" ]]; then
    echo "No dials distribution active"
    return
  fi
  if [[ "$1" != "-" && ! -d ${DIALS_DIST}/../modules/$1 ]]; then
    echo "Could not find module $1"
  else
    if [[ "$1" == "-" ]]; then
      export dest_dir=${DIALS_DIST}/../modules
    else
      export dest_dir=${DIALS_DIST}/../modules/$1
    fi
    shift
    #CURDIR=$(pwd)
    #cd $dest_dir
    #$*
    #cd $CURDIR
    ( cd $dest_dir
      $*
      )
    unset dest_dir
  fi
}

export_libtbx_env() {
   export LIBTBX_BUILD=$DIALS_DIST
   export FONTCONFIG_PATH="$LIBTBX_BUILD/../base/etc/fonts"
   export PYTHONPATH="$LIBTBX_BUILD/../modules/cctbx_project:$LIBTBX_BUILD/../modules:$LIBTBX_BUILD/../modules/cctbx_project/boost_adaptbx:$LIBTBX_BUILD/../modules/cctbx_project/libtbx/pythonpath:$LIBTBX_BUILD/lib:$LIBTBX_BUILD/../base/lib/site-python:$LIBTBX_BUILD/../base/lib/python2.7/site-packages:$PYTHONPATH"
   export LD_LIBRARY_PATH="$LIBTBX_BUILD/lib:$LIBTBX_BUILD/../base/lib64:$LIBTBX_BUILD/../base/lib:$LD_LIBRARY_PATH"
   export DYLD_LIBRARY_PATH="$LIBTBX_BUILD/lib:$LIBTBX_BUILD/../base/Python.framework/Versions/2.7/lib"
   export LIBTBX_EXPORTED_ENV=1
}

what() {
  # Find the buld path according to LIBTBX
  echo "Dials: $(_find_dials_build)"
}

