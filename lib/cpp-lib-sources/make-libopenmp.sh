
set -e
trap 'echo "exit $? due to $previous_command"' EXIT

OPENMPT_LIB="libopenmpt-0.5.8+release.autotools"

# https://stackoverflow.com/a/3466183
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
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



if [[ ! -d "${OPENMPT_LIB}" ]]; then
  wget -O- https://lib.openmpt.org/files/libopenmpt/src/${OPENMPT_LIB}.tar.gz | tar xfvz - 
  mv ${OPENMPT_LIB} open-mpt
fi

cd open-mpt



./configure --without-mpg123 --without-ogg --without-vorbis \
    --without-vorbisfile --without-portaudio --without-portaudiocpp \
    --without-flac --disable-doxygen-doc --disable-doxygen-html --disable-examples --disable-tests \
    --prefix="`pwd/.libs`"


make -j${NUMPROCS}

echo "Libs are in ./libs"
ls -l ./libs
