
set -e
trap 'echo "exit $? due to $previous_command"' EXIT

CPP_LIBRARY="pa_stable_v190700_20210406"
FRIENDLY_DIR="portaudio"
LIB_DESTINATION_DIR="`pwd`/../libportaudio"

mkdir -p ${FRIENDLY_DIR}
mkdir -p ${LIB_DESTINATION_DIR}

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


if [[ ! -d "${CPP_LIBRARY}" ]]; then
  wget -O- http://files.portaudio.com/archives/${CPP_LIBRARY}.tgz | tar xfvz - 
fi


cd ${FRIENDLY_DIR}

./configure --disable-universal 

make -j${NUMPROCS}

# echo "Libs are in ${FRIENDLY_DIR}/lib/.libs"
# find lib/.libs

cd ..




