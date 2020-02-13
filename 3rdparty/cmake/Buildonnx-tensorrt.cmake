include(ExternalProject)

find_package(Protobuf REQUIRED)
set(CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${CUDA_INCLUDE_DIRS}")

ExternalProject_Add(
  onnxtensorrt
  GIT_REPOSITORY "https://github.com/onnx/onnx-tensorrt.git"
  GIT_TAG "f4745fc"
  GIT_SUBMODULES "third_party/onnx"
  UPDATE_COMMAND ""
  PATCH_COMMAND patch -Np1 -i ${CMAKE_SOURCE_DIR}/onnx.patch
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/onnx-tensorrt
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=lib
             -DBUILD_SHARED_LIBS=ON
             -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
             -DCMAKE_CXX_FLAGS=${CXX_FLAGS}
             -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
             -DBUILD_ONNX_PYTHON=ON
             -DONNX_ML=ON
  BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} third_party/onnx/all all
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} third_party/onnx/install install
  TEST_COMMAND "")
