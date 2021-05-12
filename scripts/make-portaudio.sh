r#!/usr/bin/env bash

set -e
trap 'echo "exit $? due to $previous_command"' EXIT

CPP_LIBRARY="pa_stable_v190700_20210406"
FRIENDLY_DIR="portaudio"
LIB_DESTINATION_DIR="$(pwd)/../lib/lib/libportaudio"
mkdir -p ${LIB_DESTINATION_DIR}
echo "CPP Library files (shared objects) belong in this directory." > "$(pwd)/../lib/lib/Readme.md"


LIB_DESTINATION_DIR=`realpath ${LIB_DESTINATION_DIR}`

rm -rf ${FRIENDLY_DIR} 2>/dev/null
mkdir -p ${FRIENDLY_DIR}

# https://stackoverflow.com/a/3466183
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Darwin;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}


NUMPROCS=4
if [[ "${machine}" == "Darwin" ]]; then
  NUMPROCS=$(sysctl -n hw.ncpu)
elif [[ "${machine}" == "Linux" ]]; then
  NUMPROCS=$(nproc)
fi


if [[ ! -d "${CPP_LIBRARY}" ]]; then
  wget -O- http://files.portaudio.com/archives/${CPP_LIBRARY}.tgz | tar xfvz - 
fi

cd ${FRIENDLY_DIR}

if [[ "${machine}" == "Darwin" ]]; then
  ./configure --prefix=${LIB_DESTINATION_DIR} --exec-prefix=${LIB_DESTINATION_DIR} \
              --disable-universal 
elif [[ "${machine}" == "Linux" ]]; then
  ./configure --prefix=${LIB_DESTINATION_DIR} --exec-prefix=${LIB_DESTINATION_DIR}
fi

make -j${NUMPROCS} install
if [[ $? -eq 0 ]]; then
  cd ..
  rm -rf ${FRIENDLY_DIR}
fi




