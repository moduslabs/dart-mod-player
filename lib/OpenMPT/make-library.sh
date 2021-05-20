rm -f cmake_install.cmake *.cbp CMakeCache.txt
rm -rf build 2>/dev/null
mkdir -p build
cd build
cmake .. && make -j 4
echo Done
