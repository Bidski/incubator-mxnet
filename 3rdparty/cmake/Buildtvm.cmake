include(ExternalProject)

if(USE_CUDA)
  message("CMAKE_CUDA_COMPILER: ${CMAKE_CUDA_COMPILER}")
  message("Inferred CUDA_TOOLKIT_ROOT_DIR for TVM as: ${CUDA_TOOLKIT_ROOT_DIR}")
  set(TVM_CUDA_TOOLKIT_DIR "-DUSE_CUDA=${CUDA_TOOLKIT_ROOT_DIR}")
else(USE_CUDA)
  set(TVM_CUDA_VALUES "")
endif(USE_CUDA)

# Check for a llvm-config file. If we find one we should be able to build TVM If
# we don't find it, building is not possible
find_file(LLVM_CONFIG llvm-config)
string(FIND ${LLVM_CONFIG} "NOTFOUND" LLVM_CONFIG_FOUND)
if(NOT ${LLVM_CONFIG_FOUND} EQUAL -1)
  message(STATUS "Could not find a llvm-config file. Not building TVM Op.")
  set(USE_TVM_OP
      OFF
      CACHE BOOL "Enable use of TVM operator build system." FORCE)
endif()

# Set up the build and install commands for TVM. We do this so that TVM will
# always be downloaded (so we have access to the NNVM headers) but will only be
# built if we are able to build it
if(USE_TVM_OP)
  set(BUILD_COMMAND ${CMAKE_MAKE_PROGRAM})
  set(INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install)
else(USE_TVM_OP)
  set(BUILD_COMMAND "")
  set(INSTALL_COMMAND "")
endif(USE_TVM_OP)

ExternalProject_Add(
  tvm
  GIT_REPOSITORY "https://github.com/apache/incubator-tvm.git"
  GIT_TAG "9bd2c7b"
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/tvm
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=lib
             -DBUILD_SHARED_LIBS=ON
             -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
             -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
             -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
             -DUSE_ROCM=OFF
             -DUSE_SDACCEL=OFF
             -DUSE_AOCL=OFF
             -DUSE_OPENCL=OFF
             -DUSE_METAL=OFF
             -DUSE_VULKAN=OFF
             -DUSE_OPENGL=OFF
             -DUSE_SGX=OFF
             -DSGX_MODE=SIM
             -DRUST_SGX_SDK=
             -DUSE_RPC=ON
             -DUSE_STACKVM_RUNTIME=OFF
             -DUSE_GRAPH_RUNTIME=ON
             -DUSE_GRAPH_RUNTIME_DEBUG=OFF
             -DUSE_LLVM=${LLVM_CONFIG}
             -DUSE_BLAS=none
             -DUSE_MKL_PATH=none
             -DUSE_RANDOM=OFF
             -DUSE_NNPACK=OFF
             -DUSE_CUBLAS=OFF
             -DUSE_MIOPEN=OFF
             -DUSE_MPS=OFF
             -DUSE_ROCBLAS=OFF
             -DUSE_SORT=OFF
             -DUSE_ANTLR=OFF
             -DUSE_VTA_TSIM=OFF
             -DUSE_RELAY_DEBUG=OFF
             -DUSE_OPENMP=ON
             -DUSE_MKLDNN=OFF
             ${TVM_CUDA_BIN_DIR}
             ${TVM_CUDA_TOOLKIT_DIR}
  BUILD_COMMAND ${BUILD_COMMAND}
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  INSTALL_COMMAND ${INSTALL_COMMAND}
  TEST_COMMAND "")
