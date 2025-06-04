#!/bin/bash

# This script builds the opencv static libraries for the ESP32 and then copies the library and headers files to the asked folder. It must be runned from the opencv repository root.

# USAGE: ./build_opencv_for_esp32.sh <path-to-toolchain> <path-to-project>

set -e

# dir where the script is, no matter from where it is being called from
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"   

# path to the cmake file containing the toolchain informations
TOOLCHAIN_CMAKE_PATH=$HOME/esp/esp-idf/tools/cmake/toolchain-esp32.cmake

# path where to copy the build libs and headers 
LIB_INSTALL_PATH=$SCRIPTDIR/../lib

# list of modules to compile
OPENCV_MODULES_LIST=core,imgproc,objdetect

echo "################################################################################"
echo "######################## build_opencv_for_esp32 script #########################"
echo "################################################################################"

## get script arguments ###
if [ -z "$1" ]
  then
    echo "Using default toolchain cmake file path: ${TOOLCHAIN_CMAKE_PATH}" 
else 
     TOOLCHAIN_CMAKE_PATH=$1
     echo "Using toolchain cmake file path: ${TOOLCHAIN_CMAKE_PATH}"
fi

if [ -z "$2" ]
  then
    echo "Will be installed in default library install path: ${LIB_INSTALL_PATH}/opencv" 
else 
     LIB_INSTALL_PATH=$2
     echo "Will be installed in user-defined library install path: ${LIB_INSTALL_PATH}/opencv"
fi

# get source directory from third argument or use default
if [ -z "$3" ]; then
    OPENCV_SOURCE_DIR=$(realpath "$SCRIPTDIR/../../")
    echo "Using default OpenCV source dir: $OPENCV_SOURCE_DIR"
else
    OPENCV_SOURCE_DIR=$(realpath "$3")
    echo "Using user-defined OpenCV source dir: $OPENCV_SOURCE_DIR"
fi



CMAKE_ARGS="\
-DCMAKE_BUILD_TYPE=Release \
-DESP32=ON \
-DWITH_ADE=OFF \
-DBUILD_opencv_ml=OFF \
-DBUILD_opencv_gapi=OFF \
-DBUILD_SHARED_LIBS=OFF \
-DCV_DISABLE_OPTIMIZATION=OFF \
-DWITH_IPP=OFF \
-DWITH_TBB=OFF \
-DWITH_OPENMP=OFF \
-DWITH_PTHREADS_PF=OFF \
-DWITH_QUIRC=OFF \
-DWITH_1394=OFF \
-DWITH_CUDA=OFF \
-DWITH_OPENCL=OFF \
-DWITH_OPENCLAMDFFT=OFF \
-DWITH_OPENCLAMDBLAS=OFF \
-DWITH_VA_INTEL=OFF \
-DWITH_EIGEN=OFF \
-DWITH_GSTREAMER=OFF \
-DWITH_GTK=OFF \
-DWITH_JASPER=OFF \
-DWITH_JPEG=OFF \
-DWITH_WEBP=OFF \
-DBUILD_ZLIB=ON \
-DBUILD_PNG=ON \
-DWITH_TIFF=OFF \
-DWITH_V4L=OFF \
-DWITH_LAPACK=OFF \
-DWITH_ITT=OFF \
-DWITH_PROTOBUF=OFF \
-DWITH_IMGCODEC_HDR=OFF \
-DWITH_IMGCODEC_SUNRASTER=OFF \
-DWITH_IMGCODEC_PXM=OFF \
-DWITH_IMGCODEC_PFM=OFF \
-DBUILD_LIST=${OPENCV_MODULES_LIST} \
-DBUILD_JAVA=OFF \
-DBUILD_opencv_python=OFF \
-DBUILD_opencv_java=OFF \
-DBUILD_opencv_apps=OFF \
-DBUILD_PACKAGE=OFF \
-DBUILD_PERF_TESTS=OFF \
-DBUILD_TESTS=OFF \
-DCV_ENABLE_INTRINSICS=OFF \
-DCV_TRACE=OFF \
-DOPENCV_ENABLE_MEMALIGN=OFF \
-DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_CMAKE_PATH} \
-DBUILD_SHARED_LIBS=OFF \
-DBUILD_DOCS=OFF \
-DBUILD_EXAMPLES=OFF \
-DWITH_OPENCL=OFF \
-DWITH_PTHREADS_PF=OFF \
-DWITH_QUIRC=OFF \
-DWITH_JPEG=OFF \
-DBUILD_OPENJPEG=OFF \
-DWITH_OPENJPEG=OFF \
-DWITH_PNG=OFF \
-DWITH_OPENEXR=OFF \
-DWITH_FFMPEG=OFF \
-DCV_DISABLE_OPTIMIZATION=ON \
-DOPENCV_MALLOC_FAST=OFF \
-DOPENCV_MALLOC_ALIGNED=OFF \
-DENABLE_CXX_EXCEPTIONS=OFF "



### configure and build opencv ###
#cd "$OPENCV_SOURCE_DIR"
#rm -rf build/ && mkdir -p build/ && cd build
BUILD_DIR="${LIB_INSTALL_PATH}/opencv/build"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# configure with cmake
echo "================================================================================"
echo "Configuring with cmake ${CMAKE_ARGS} :"
echo "================================================================================"
# launch cmake with args and parse list of modules to be build in a variable
#OPENCV_MODULES_LIST=`cmake $CMAKE_ARGS .. | tee /dev/tty | grep 'To be built' | cut -f2 -d ':' | xargs | tr ' ' ','`
#OPENCV_MODULES_LIST=$(cmake $CMAKE_ARGS "$OPENCV_SOURCE_DIR" | tee /dev/tty | grep 'To be built' | cut -f2 -d ':' | xargs | tr ' ' ',')
#echo $OPENCV_MODULES_LIST
cmake $CMAKE_ARGS "$OPENCV_SOURCE_DIR" | tee cmake_output.log
grep 'To be built:' cmake_output.log

read -p "Don't forget to check the cmake summary! Continue ? [y/N]"  prompt
if [ "${prompt}" != "y" ] && [ "${prompt}" != "Y" ] && [ "${prompt}" != "yes" ]; then 
    echo "aborted."
	exit 1
fi

# fix of the generated file alloc.c 
# cp $SCRIPTDIR/resources/alloc_fix.cpp ./3rdparty/ade/ade-0.1.1f/sources/ade/source/alloc.cpp

# compiling with all power!
echo "================================================================================"
echo "Compiling with make -j"
echo "================================================================================"
make -j1

### installing in output directory ###
echo "================================================================================"
echo "Installing in ${LIB_INSTALL_PATH}"
echo "================================================================================"
# copying opencv modules libs
mkdir -p $LIB_INSTALL_PATH/opencv
cp lib/* $LIB_INSTALL_PATH/opencv

# copying 3rdparty libs
mkdir -p $LIB_INSTALL_PATH/opencv/3rdparty
cp 3rdparty/lib/* $LIB_INSTALL_PATH/opencv/3rdparty

# copying headers
mkdir -p $LIB_INSTALL_PATH/opencv/opencv2
cp opencv2/* $LIB_INSTALL_PATH/opencv/opencv2
#cp ../include/opencv2/opencv.hpp $LIB_INSTALL_PATH/opencv/opencv2/
if [ -f "$OPENCV_SOURCE_DIR/include/opencv2/opencv.hpp" ]; then
    cp "$OPENCV_SOURCE_DIR/include/opencv2/opencv.hpp" "$LIB_INSTALL_PATH/opencv/opencv2/"
else
    echo "Warning: opencv.hpp not found at expected location."
fi


IFS=',' read -r -a modules <<< "$OPENCV_MODULES_LIST"
for elt in "${modules[@]}"
do
    echo "Module ${elt}"
	cp -r "$OPENCV_SOURCE_DIR/modules/${elt}/include/opencv2" "$LIB_INSTALL_PATH/opencv"

done

echo "installation done."


