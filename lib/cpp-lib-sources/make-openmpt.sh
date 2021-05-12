#!/usr/bin/env bash
# sudo apt-get install -y libsndfile-dev

set -e
trap 'echo "exit $? due to $previous_command"' EXIT

OPENMPT_LIB="libopenmpt-0.5.8+release.autotools"
FRIENDLY_DIR="openmpt"
mkdir -p $(pwd)/../cpp-lib/libopenmpt

LIB_DESTINATION_DIR=`realpath $(pwd)/../cpp-lib/libopenmpt`

rm -rf ${OPENMPT_LIB} ${FRIENDLY_DIR} 2>/dev/null
mkdir -p ${LIB_DESTINATION_DIR}

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



wget -O- https://lib.openmpt.org/files/libopenmpt/src/${OPENMPT_LIB}.tar.gz | tar xvfz - 
mv ${OPENMPT_LIB} "${FRIENDLY_DIR}/"

cd ${FRIENDLY_DIR}



./configure --without-mpg123 --without-ogg --without-vorbis --without-libsndfile \
    --without-vorbisfile --without-portaudio --without-portaudiocpp \
    --without-flac --disable-doxygen-doc --disable-doxygen-html --disable-examples --disable-tests \
    --prefix=${LIB_DESTINATION_DIR} --exec-prefix=${LIB_DESTINATION_DIR}


make -j${NUMPROCS} install

