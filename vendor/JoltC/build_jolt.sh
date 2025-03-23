mkdir build
cd vendor/JoltC/build
cmake ../JoltC
cmake  --build . --config Release
cd ..
mkdir lib
cp build/Release/joltc.lib lib/joltc.lib
cp build/JoltPhysics/Build/Release/Jolt.lib lib/jolt.lib