cmake_minimum_required(VERSION 3.13)

# workaround to store CMAKE_CROSSCOMPILING because is getting reset by the
# project command
if(CMAKE_CROSSCOMPILING)
  set(__CMAKE_CROSSCOMPILING ${CMAKE_CROSSCOMPILING})
  set(__CMAKE_CROSSCOMPILING_OVERRIDE ON)
endif()

if(__CMAKE_CROSSCOMPILING_OVERRIDE)
  set(CMAKE_CROSSCOMPILING ${__CMAKE_CROSSCOMPILING})
endif()

project(mxnet CXX)
message(
  STATUS "CMake version '${CMAKE_VERSION}' using generator '${CMAKE_GENERATOR}'"
)
if(USE_CUDA)
  cmake_minimum_required(VERSION 3.13.2) # CUDA 10 (Turing) detection available
                                         # starting 3.13.2
  enable_language(CUDA)
  set(CMAKE_CUDA_STANDARD 11)
  include(CheckCXXCompilerFlag)
  if(USE_CXX14_IF_AVAILABLE)
    check_cxx_compiler_flag("-std=c++14" SUPPORT_CXX14)
    if(SUPPORT_CXX14)
      set(CMAKE_CUDA_STANDARD 14)
    endif()
  endif()
  set(CMAKE_CUDA_STANDARD_REQUIRED ON)
endif()

if(UNIX)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

if(USE_CCACHE)
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    set(CMAKE_CUDA_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  else()
    message(
      STATUS
        "Could not find CCache. Consider installing CCache to speed up compilation."
    )
  endif()
endif()

if(MSVC)
  set(SYSTEM_ARCHITECTURE x86_64)
  enable_language(ASM_MASM)
else()
  execute_process(
    COMMAND uname -m
    COMMAND tr -d '\n'
    OUTPUT_VARIABLE SYSTEM_ARCHITECTURE)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Distribution"
   AND UNIX
   AND NOT APPLE)
  set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
  set(CMAKE_INSTALL_RPATH $ \{ORIGIN\})
  # Enforce DT_PATH instead of DT_RUNPATH
  set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--disable-new-dtags")
  set(CMAKE_EXE_LINKER_FLAGS "-Wl,--disable-new-dtags")
endif()

set(EXTRA_OPERATORS
    ""
    CACHE PATH "EXTRA OPERATORS PATH")

message(STATUS "CMAKE_CROSSCOMPILING ${CMAKE_CROSSCOMPILING}")
message(STATUS "CMAKE_HOST_SYSTEM_PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_SYSTEM_PROCESSOR ${CMAKE_SYSTEM_PROCESSOR}")

message(STATUS "CMAKE_SYSTEM_NAME ${CMAKE_SYSTEM_NAME}")

set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR} ${CMAKE_MODULE_PATH})
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules
                      ${CMAKE_MODULE_PATH})

if("$ENV{VERBOSE}" STREQUAL "1")
  message(STATUS " Verbose Makefile ACTIVATED")
  set(CMAKE_VERBOSE_MAKEFILE ON)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/Utils.cmake)

include(CMakeDependentOption)
# Some things have order. This must be put in front alone
option(USE_CUDA "Build with CUDA support" ON)
set(MXNET_CUDA_ARCH
    "Auto"
    CACHE
      STRING
      "Target NVIDIA GPU achitecture.
Format: Auto | Common | All | LIST(ARCH_AND_PTX ...)
- \"Auto\" detects local machine GPU compute arch at runtime.
- \"Common\" and \"All\" cover common and entire subsets of architectures
- ARCH_AND_PTX : NAME | NUM.NUM | NUM.NUM(NUM.NUM) | NUM.NUM+PTX
- NAME: Fermi Kepler Maxwell Kepler+Tegra Kepler+Tesla Maxwell+Tegra Pascal Volta Turing
- NUM: Any number. Only those pairs are currently accepted by NVCC though:
       2.0 2.1 3.0 3.2 3.5 3.7 5.0 5.2 5.3 6.0 6.2 7.0 7.2 7.5")
option(USE_NCCL "Use NVidia NCCL with CUDA" OFF)
option(USE_OPENCV "Build with OpenCV support" ON)
option(USE_OPENMP "Build with Openmp support" ON)
cmake_dependent_option(USE_CUDNN "Build with cudnn support" ON "USE_CUDA" OFF
)# one could set CUDNN_ROOT for search path
cmake_dependent_option(USE_NVTX "Build with nvtx support if found" ON
                       "USE_CUDA" OFF)
cmake_dependent_option(USE_SSE "Build with x86 SSE instruction support" ON
                       "NOT ARM" OFF)
option(USE_F16C "Build with x86 F16C instruction support" ON) # autodetects
                                                              # support if ON
option(USE_LAPACK "Build with lapack support" ON)
option(USE_MKL_IF_AVAILABLE "Use MKL if found" ON)
if(USE_MKL_IF_AVAILABLE
   AND (NOT APPLE)
   AND (NOT MSVC)
   AND (CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
   AND (NOT CMAKE_CROSSCOMPILING))
  option(USE_MKLDNN "Build with MKL-DNN support" ON)
else()
  option(USE_MKLDNN "Build with MKL-DNN support" OFF)
endif()
if(NOT MSVC)
  option(USE_OPERATOR_TUNING "Enable auto-tuning of operators" ON)
else()
  option(USE_OPERATOR_TUNING "Enable auto-tuning of operators" OFF)
endif()
option(USE_GPERFTOOLS "Build with GPerfTools support" OFF)
option(USE_JEMALLOC "Build with Jemalloc support" OFF)
option(USE_DIST_KVSTORE "Build with DIST_KVSTORE support" OFF)
option(USE_PLUGINS_WARPCTC "Use WARPCTC Plugins" OFF)
option(USE_PLUGIN_CAFFE "Use Caffe Plugin" OFF)
option(USE_CPP_PACKAGE "Build C++ Package" OFF)
option(USE_MXNET_LIB_NAMING "Use MXNet library naming conventions." ON)
option(USE_GPROF "Compile with gprof (profiling) flag" OFF)
option(USE_CXX14_IF_AVAILABLE "Build with C++14 if the compiler supports it"
       OFF)
option(USE_VTUNE "Enable use of Intel Amplifier XE (VTune)" OFF) # one could set
                                                                 # VTUNE_ROOT
                                                                 # for search
                                                                 # path
option(USE_TVM_OP "Enable use of TVM operator build system." OFF)
option(ENABLE_CUDA_RTC "Build with CUDA runtime compilation support" ON)
option(BUILD_CPP_EXAMPLES "Build cpp examples" ON)
option(INSTALL_EXAMPLES "Install the example source files." OFF)
option(USE_SIGNAL_HANDLER "Print stack traces on segfaults." ON)
option(USE_TENSORRT "Enable inference optimization with TensorRT." OFF)
option(USE_ASAN "Enable Clang/GCC ASAN sanitizers." OFF)
option(ENABLE_TESTCOVERAGE
       "Enable compilation with test coverage metric output" OFF)
option(USE_INT64_TENSOR_SIZE
       "Use int64_t to represent the total number of elements in a tensor" OFF)
option(BUILD_CYTHON_MODULES "Build cython modules." OFF)
cmake_dependent_option(
  USE_SPLIT_ARCH_DLL "Build a separate DLL for each Cuda arch (Windows only)."
  ON "MSVC" OFF)
cmake_dependent_option(
  USE_CCACHE "Attempt using CCache to wrap the compilation" ON "UNIX" OFF)

# ##############################################################################
# GATHER SOURCES
# ##############################################################################

file(GLOB_RECURSE SOURCE "src/*.cc" "src/*.h" "include/*.h")
file(GLOB_RECURSE CUDA "src/*.cu" "src/*.cuh")

# add nnvm to source
file(
  GLOB_RECURSE
  NNVMSOURCE
  3rdparty/tvm/nnvm/src/c_api/*.cc
  3rdparty/tvm/nnvm/src/core/*.cc
  3rdparty/tvm/nnvm/src/pass/*.cc
  3rdparty/tvm/nnvm/src/c_api/*.h
  3rdparty/tvm/nnvm/src/core/*.h
  3rdparty/tvm/nnvm/src/pass/*.h
  3rdparty/tvm/nnvm/include/*.h)
list(APPEND SOURCE ${NNVMSOURCE})

# Add source groups
file(GLOB_RECURSE GROUP_SOURCE "src/*.cc" "3rdparty/tvm/nnvm/*.cc"
     "plugin/*.cc")
file(GLOB_RECURSE GROUP_Include "src/*.h" "3rdparty/tvm/nnvm/*.h" "plugin/*.h")
file(
  GLOB_RECURSE
  GROUP_CUDA
  "src/*.cu"
  "src/*.cuh"
  "plugin/*.cu"
  "plugin/*.cuh"
  "3rdparty/nvidia_cub/cub/*.cuh")
assign_source_group("Source" ${GROUP_SOURCE})
assign_source_group("Include" ${GROUP_Include})
assign_source_group("CUDA" ${GROUP_CUDA})

# ##############################################################################
# INITIALISE LIBRARY LIST
# ##############################################################################

if(NOT mxnet_LINKER_LIBS)
  set(mxnet_LINKER_LIBS "")
endif(NOT mxnet_LINKER_LIBS)

if(NOT mxnet_COMPILE_OPTIONS)
  set(mxnet_COMPILE_OPTIONS "")
endif(NOT mxnet_COMPILE_OPTIONS)

if(NOT mxnet_COMPILE_DEFINITIONS)
  set(mxnet_COMPILE_DEFINITIONS "")
endif(NOT mxnet_COMPILE_DEFINITIONS)

if(NOT mxnet_LINKER_OPTIONS)
  set(mxnet_LINKER_OPTIONS "")
endif(NOT mxnet_LINKER_OPTIONS)

if(NOT mxnet_INCLUDE_DIRS)
  set(mxnet_INCLUDE_DIRS "")
endif(NOT mxnet_INCLUDE_DIRS)

if(NOT mxnet_LINK_DIRS)
  set(mxnet_LINK_DIRS "")
endif(NOT mxnet_LINK_DIRS)

# ##############################################################################
# SET COMPILER OPTIONS
# ##############################################################################

# Switch off modern thread local for dmlc-core, please see:
# https://github.com/dmlc/dmlc-core/issues/571#issuecomment-543467484
list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_MODERN_THREAD_LOCAL=0)
# disable stack trace in exception by default.
list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_LOG_STACK_TRACE_SIZE=0)
list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_LOG_FATAL_THROW=1)

if(MSVC)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DWIN32_LEAN_AND_MEAN)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_USE_CXX11)
  list(APPEND mxnet_COMPILE_DEFINITIONS -D_SCL_SECURE_NO_WARNINGS)
  list(APPEND mxnet_COMPILE_DEFINITIONS -D_CRT_SECURE_NO_WARNINGS)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_EXPORTS)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DNNVM_EXPORTS)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_STRICT_CXX11)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DNOMINMAX)
  list(APPEND mxnet_COMPILE_OPTIONS "/bigobj")
else()
  include(CheckCXXCompilerFlag)
  if(USE_CXX14_IF_AVAILABLE)
    check_cxx_compiler_flag("-std=c++14" SUPPORT_CXX14)
  endif()
  check_cxx_compiler_flag("-std=c++11" SUPPORT_CXX11)
  check_cxx_compiler_flag("-std=c++0x" SUPPORT_CXX0X)

  list(APPEND mxnet_COMPILE_OPTIONS "-Wall")
  list(APPEND mxnet_COMPILE_OPTIONS "-Wno-unknown-pragmas")
  list(APPEND mxnet_COMPILE_OPTIONS "-Wno-sign-compare")

  if("${CMAKE_CXX_COMPILER_ID}" MATCHES ".*Clang$")
    list(APPEND mxnet_COMPILE_OPTIONS "-Wno-braced-scalar-init")
  endif()

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND mxnet_COMPILE_OPTIONS "-O0")
    list(APPEND mxnet_COMPILE_OPTIONS "-D_GLIBCXX_ASSERTIONS")
  elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    list(APPEND mxnet_COMPILE_OPTIONS "-O3")
    list(APPEND mxnet_COMPILE_OPTIONS "-D_GLIBCXX_ASSERTIONS")
  else()
    list(APPEND mxnet_COMPILE_OPTIONS "-O3")
  endif()

  list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_USE_CXX11=1)
  if(SUPPORT_CXX14)
    list(APPEND mxnet_COMPILE_DEFINITIONS -DDMLC_USE_CXX14=1)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
  elseif(SUPPORT_CXX11)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
  elseif(SUPPORT_CXX0X)
    list(APPEND mxnet_COMPILE_DEFINITIONS "-std=c++0x")
  endif()
endif(MSVC)

if(USE_GPROF)
  message(STATUS "Using GPROF")
  list(APPEND mxnet_COMPILE_OPTIONS "-fno-omit-frame-pointer")
  list(APPEND mxnet_COMPILE_OPTIONS "-g")
  list(APPEND mxnet_COMPILE_OPTIONS "-pg")
  list(APPEND mxnet_LINKER_OPTIONS "-g")
  list(APPEND mxnet_LINKER_OPTIONS "-pg")
endif()

if(USE_VTUNE)
  message(STATUS "Using VTUNE")
  if(NOT VTUNE_ROOT)
    set(VTUNE_ROOT /opt/intel/vtune_amplifier_xe_2017)
  endif()
  list(APPEND mxnet_COMPILE_OPTIONS "-fno-omit-frame-pointer")
  list(APPEND mxnet_COMPILE_OPTIONS "-g")
  list(APPEND mxnet_COMPILE_OPTIONS "-pg")
  list(APPEND mxnet_LINKER_OPTIONS "-g")
  list(APPEND mxnet_LINKER_OPTIONS "-pg")
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_VTUNE=1)
  list(APPEND mxnet_INCLUDE_DIRS ${VTUNE_ROOT}/include)
  list(APPEND mxnet_LINKER_LIBS ${VTUNE_ROOT}/lib64/libittnotify.a)
  list(APPEND mxnet_LINKER_LIBS dl)
endif()

# please note that when you enable this, you might run into an linker not being
# able to work properly due to large code injection. you can find more
# information here https://github.com/apache/incubator-mxnet/issues/15971
if(ENABLE_TESTCOVERAGE)
  message(
    STATUS
      "Compiling with test coverage support enabled. This will result in additional files being written to your source directory!"
  )
  find_program(GCOV_PATH gcov)
  if(NOT GCOV_PATH)
    message(FATAL_ERROR "gcov not found! Aborting...")
  endif() # NOT GCOV_PATH

  list(APPEND mxnet_COMPILE_OPTIONS "--coverage")
  list(APPEND mxnet_LINKER_OPTIONS "--coverage")
  list(APPEND mxnet_LINKER_LIBS gcov)
endif()

if(USE_ASAN)
  list(APPEND mxnet_COMPILE_OPTIONS "-fno-omit-frame-pointer")
  list(APPEND mxnet_COMPILE_OPTIONS "-fsanitize=address")
  list(APPEND mxnet_LINKER_OPTIONS "-fno-omit-frame-pointer")
  list(APPEND mxnet_LINKER_OPTIONS "-fsanitize=address")
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    list(APPEND mxnet_LINKER_LIBS -static-libasan)
  else(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    list(APPEND mxnet_LINKER_LIBS asan)
  endif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
endif()

if(USE_OPERATOR_TUNING AND USE_OPENMP)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_OPERATOR_TUNING=1)
endif()

# Prevent stripping out symbols (operator registrations, for example)
if(NOT MSVC AND NOT APPLE)
  set(BEGIN_WHOLE_ARCHIVE -Wl,--whole-archive)
  set(END_WHOLE_ARCHIVE -Wl,--no-whole-archive)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # using regular Clang or AppleClang
  set(BEGIN_WHOLE_ARCHIVE -Wl,-force_load)
endif()

if(MSVC)
  foreach(flag_var mxnet_COMPILE_OPTIONS)
    if(${flag_var} MATCHES "/MD")
      string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endif(${flag_var} MATCHES "/MD")
  endforeach(flag_var)
endif()

if(MSVC)
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
    list(APPEND mxnet_COMPILE_OPTIONS "/Gy")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:REF")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:ICF")
  elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
    list(APPEND mxnet_COMPILE_OPTIONS "/Gy")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:REF")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:ICF")
  elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
    list(APPEND mxnet_COMPILE_OPTIONS "/Gy")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:REF")
    list(APPEND mxnet_LINKER_OPTIONS "/OPT:ICF")
  endif()
endif()

# ##############################################################################
# BUILD THIRD PARTY DEPENDENCIES
# ##############################################################################

# TVM Op
if(USE_TVM_OP AND EXISTS ${CMAKE_BINARY_DIR}/lib/libtvm_runtime.so)
  if(NOT Python3_EXECUTABLE)
    find_package(PythonInterp 3 REQUIRED)
    set(Python3_EXECUTABLE
        ${PYTHON_EXECUTABLE}
        CACHE FILEPATH "Path to the python3 executable")
    if(NOT Python3_EXECUTABLE)
      message(FATAL_ERROR "No python3 interpreter found to build TVM operators")
    endif()
  endif()

  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_TVM_OP=1)
  list(APPEND mxnet_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/include)
  list(APPEND mxnet_LINK_DIRS ${CMAKE_BINARY_DIR}/lib)
  list(APPEND mxnet_LINKER_LIBS tvm_runtime)

  set(TVM_OP_COMPILE_OPTIONS
      "-o${CMAKE_CURRENT_BINARY_DIR}" "--config"
      "${CMAKE_CURRENT_BINARY_DIR}/tvmop.conf" "-L"
      "${CMAKE_CURRENT_BINARY_DIR}/3rdparty/tvm")
  if(USE_CUDA)
    set(TVM_OP_COMPILE_OPTIONS "${TVM_OP_COMPILE_OPTIONS}" "--cuda-arch"
                               "\"${CUDA_ARCH_FLAGS}\"")
  endif()

  # add_custom_command( TARGET mxnet POST_BUILD COMMAND ${CMAKE_COMMAND} -E env
  # PYTHONPATH="${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/tvm/python:${CMAKE_CURRENT_
  # SOURCE_DIR}/3rdparty/tvm/topi/python:${CMAKE_CURRENT_SOURCE_DIR}/contrib" LD
  # _LIBRARY_PATH=${CMAKE_CURRENT_BINARY_DIR}:${CMAKE_CURRENT_BINARY_DIR}/3rdpar
  # ty/tvm:$ENV{LD_LIBRARY_PATH} ${Python3_EXECUTABLE}
  # ${CMAKE_CURRENT_SOURCE_DIR}/contrib/tvmop/compile.py
  # ${TVM_OP_COMPILE_OPTIONS})
else(USE_TVM_OP AND EXISTS ${CMAKE_BINARY_DIR}/lib/libtvm_runtime.so)
  set(USE_TVM_OP OFF)
endif(USE_TVM_OP AND EXISTS ${CMAKE_BINARY_DIR}/lib/libtvm_runtime.so)

# ONNX TensorRT
if(USE_TENSORRT)
  if(NOT EXISTS ${CMAKE_BINARY_DIR}/lib/libonnx.so
     OR NOT EXISTS ${CMAKE_BINARY_DIR}/lib/libnvonnxparser.so)
    message(STATUS ${CMAKE_BINARY_DIR}/lib/libnvonnx.so)
    message(SEND_ERROR "USE_TENSORRT set but onnx-tensorrt not built")
    set(USE_TENSORRT OFF)
  else()
    message(STATUS "Using TensorRT")
    list(
      APPEND
      mxnet_LINKER_LIBS
      nvinfer
      nvonnxparser
      nvonnxparser_runtime
      onnx_proto
      onnx
      ${PROTOBUF_LIBRARY})
    list(APPEND mxnet_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/include)
    list(APPEND mxnet_LINK_DIRS ${CMAKE_BINARY_DIR}/lib)
  endif()
endif()

# DNNL
if(USE_MKLDNN)
  # CPU architecture (e.g., C5) can't run on another architecture (e.g., g3).
  if(MSVC)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
      list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
      list(APPEND mxnet_COMPILE_OPTIONS "/MT")
    elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
      list(APPEND mxnet_COMPILE_OPTIONS "/EHsc")
      list(APPEND mxnet_COMPILE_OPTIONS "/MT")
      list(APPEND mxnet_COMPILE_OPTIONS "/Gy")
    endif()
  endif()

  find_package(dnnl REQUIRED)
  list(APPEND mxnet_LINKER_LIBS DNNL::dnnl)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_MKLDNN=1)
endif()

# DLPACK
find_package(dlpack REQUIRED)
list(APPEND mxnet_LINKER_LIBS dlpack::dlpack)

# DMLC
find_package(dmlc REQUIRED)
list(APPEND mxnet_LINKER_LIBS dmlc::dmlc)

# PS-LITE
if(USE_DIST_KVSTORE)
  if(NOT EXISTS ${CMAKE_BINARY_DIR}/lib/libpslite.so)
    message(ERROR "USE_DIST_KVSTORE set but ps-lite not built")
    set(USE_DIST_KVSTORE OFF)
  else()
    list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_DIST_KVSTORE)
    list(APPEND mxnet_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/include)
    list(APPEND mxnet_LINK_DIRS ${CMAKE_BINARY_DIR}/lib)
    list(APPEND mxnet_LINKER_LIBS pslite)
  endif()
endif()

# OPENMP
if(USE_OPENMP)
  find_package(OpenMP REQUIRED)
  if(OPENMP_FOUND)
    list(APPEND mxnet_LINKER_LIBS OpenMP::OpenMP_CXX)
    list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_OPENMP=1)
  else(OPENMP_FOUND)
    # This should build on Windows, but there's some problem and I don't have a
    # Windows box, so could a Windows user please fix?
    if(SYSTEM_ARCHITECTURE STREQUAL "x86_64"
       AND NOT CMAKE_BUILD_TYPE STREQUAL "Distribution"
       AND NOT MSVC
       AND NOT CMAKE_CROSSCOMPILING)
      list(REMOVE_ITEM mxnet_LINKER_LIBS iomp5)
      list(APPEND mxnet_LINKER_LIBS omp)
      if(UNIX)
        set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
        set(THREADS_PREFER_PTHREAD_FLAG TRUE)
        find_package(Threads REQUIRED)
        list(APPEND mxnet_LINKER_LIBS Threads::Threads)
      endif()
      list(APPEND mxnet_LINKER_LIBS OpenMP::OpenMP_CXX)
      list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_OPENMP=1)
    endif()
  endif(OPENMP_FOUND)
elseif(UNIX AND NOT ANDROID)
  set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
  set(THREADS_PREFER_PTHREAD_FLAG TRUE)
  find_package(Threads REQUIRED)
  list(APPEND mxnet_LINKER_LIBS Threads::Threads)
endif()

# CTEST AND GOOGLETEST
include(CTest)
find_package(GTest REQUIRED)

# MSHADOW
add_subdirectory("3rdparty/mshadow")
list(APPEND mxnet_LINKER_LIBS mshadow)

# ##############################################################################
# FIND DEPENDENCIES
# ##############################################################################

set(ALT_MALLOC_FLAGS "-fno-builtin-malloc" "-fno-builtin-calloc"
                     "-fno-builtin-realloc" "-fno-builtin-free")

# GPERFTOOLS
if(USE_GPERFTOOLS)
  find_package(Gperftools)
  if(GPERFTOOLS_FOUND)
    message(STATUS "Using Gperftools malloc (tcmalloc)")
    list(APPEND mxnet_INCLUDE_DIRS ${GPERFTOOLS_INCLUDE_DIR})
    list(APPEND mxnet_COMPILE_OPTIONS ${ALT_MALLOC_FLAGS})
    list(APPEND mxnet_LINKER_LIBS ${GPERFTOOLS_LIBRARIES})
    set(USE_JEMALLOC 0)
  endif()
endif()

# JEMALLOC
if(USE_JEMALLOC)
  if(GPERFTOOLS_FOUND)
    message(
      ERROR
      " Only one of USE_JEMALLOC and USE_GPERFTOOLS can be defined at once")
  endif()
  find_package(JeMalloc)
  if(JEMALLOC_FOUND)
    message(STATUS "Using JEMalloc malloc")
    list(APPEND mxnet_COMPILE_DEFINITIONS -DUSE_JEMALLOC)
    list(APPEND mxnet_COMPILE_OPTIONS ${ALT_MALLOC_FLAGS})
    list(APPEND mxnet_INCLUDE_DIRS ${JEMALLOC_INCLUDE_DIRS})
    list(APPEND mxnet_LINKER_LIBS ${JEMALLOC_LIBRARIES})
  endif()
endif()

# OPENCV
if(USE_OPENCV)
  find_package(OpenCV COMPONENTS core highgui imgproc imgcodecs)
  if(NOT OpenCV_FOUND) # if not OpenCV 3.x, then imgcodecs are not found
    message(STATUS "OpenCV imgcodecs missing")
    find_package(OpenCV REQUIRED COMPONENTS core highgui imgproc)
  endif()
  list(APPEND mxnet_INCLUDE_DIRS ${OpenCV_INCLUDE_DIRS})
  list(APPEND mxnet_LINKER_LIBS ${OpenCV_LIBS})
  message(STATUS "OpenCV ${OpenCV_VERSION} found (${OpenCV_CONFIG_PATH})")
  message(STATUS " OpenCV_LIBS=${OpenCV_LIBS}")
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_OPENCV=1)
else(USE_OPENCV)
  message(STATUS "OpenCV Disabled")
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_OPENCV=0)
endif()

# LAPACK
if(USE_LAPACK)
  message("USE_LAPACK is ON")
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_LAPACK=1)
  # In the CMAKE_BUILD_TYPE="Distribution" case, we link against Blas libraries
  # that already provide lapack symbols. Thus -llapack would be wrong.
  if(NOT MSVC AND NOT CMAKE_BUILD_TYPE STREQUAL "Distribution")
    list(APPEND mxnet_LINKER_LIBS lapack)
  endif()
endif()

# RTLIB
if(UNIX)
  find_library(RTLIB rt)
  if(RTLIB)
    list(APPEND mxnet_LINKER_LIBS ${RTLIB})
  endif()
endif()

# CUDNN
if(USE_CUDNN)
  find_package(CUDNN)
  if(CUDNN_FOUND)
    list(APPEND mxnet_COMPILE_DEFINITIONS -DUSE_CUDNN)
    list(APPEND mxnet_INCLUDE_DIRS ${CUDNN_INCLUDE})
    list(APPEND mxnet_LINKER_LIBS ${CUDNN_LIBRARY})
  else()
    set(USE_CUDNN OFF)
  endif()
endif()

if(USE_CUDA)
  # CUDA_SELECT_NVCC_ARCH_FLAGS is not deprecated, though part of deprecated
  # FindCUDA https://gitlab.kitware.com/cmake/cmake/issues/19199
  include(${CMAKE_ROOT}/Modules/FindCUDA/select_compute_arch.cmake)
  cuda_select_nvcc_arch_flags(CUDA_ARCH_FLAGS ${MXNET_CUDA_ARCH})
  message(
    "-- CUDA: Using the following NVCC architecture flags ${CUDA_ARCH_FLAGS}")
  set(arch_code_list)
  foreach(arch_str ${CUDA_ARCH_FLAGS})
    if((arch_str MATCHES ".*sm_[0-9]+"))
      string(REGEX REPLACE ".*sm_([0-9]+)" "\\1" arch_code ${arch_str})
      list(APPEND arch_code_list ${arch_code})
    endif()
  endforeach()

  string(REPLACE ";" " " CUDA_ARCH_FLAGS_SPACES "${CUDA_ARCH_FLAGS}")

  find_package(CUDAToolkit REQUIRED cublas cufft cusolver curand
               OPTIONAL_COMPONENTS nvToolsExt nvrtc)

  list(
    APPEND
    mxnet_LINKER_LIBS
    CUDA::cudart
    CUDA::cublas
    CUDA::cufft
    CUDA::cusolver
    CUDA::curand)
  if(ENABLE_CUDA_RTC)
    if(CUDA_nvrtc_LIBRARY)
      list(APPEND mxnet_LINKER_LIBS CUDA::nvrtc cuda)
      list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_ENABLE_CUDA_RTC=1)
    else()
      message(
        FATAL_ERROR
          "ENABLE_CUDA_RTC=ON, but failed to find NVRTC. CMake will exit.")
    endif()
  endif()
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_CUDA=1)

  if(USE_NCCL)
    find_package(NCCL)
    if(NCCL_FOUND)
      list(APPEND mxnet_INCLUDE_DIRS ${NCCL_INCLUDE_DIRS})
      list(APPEND mxnet_LINKER_LIBS ${NCCL_LIBRARIES})
      list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_NCCL=1)
    else()
      list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_NCCL=0)
      message(WARNING "Could not find NCCL libraries")
    endif()
  endif()
  if(UNIX)
    if(USE_NVTX AND CUDA_nvToolsExt_LIBRARY)
      list(APPEND mxnet_LINKER_LIBS CUDA::nvToolsExt)
      list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_NVTX=1)
    else()
      message("Building without NVTX support.")
    endif()
  endif()

  list(APPEND mxnet_INCLUDE_DIRS ${CUDAToolkit_INCLUDE_DIRS})
  list(APPEND mxnet_LINK_DIRS ${CUDAToolkit_LIBRARY_DIR})
endif()

# BLAS
include(cmake/ChooseBlas.cmake)

# ##############################################################################
# PLUGINS
# ##############################################################################

if(USE_PLUGINS_WARPCTC)
  set(WARPCTC_INCLUDE
      ""
      CACHE PATH "WARPCTC include")
  set(WARPCTC_LIB_DEBUG
      ""
      CACHE FILEPATH "WARPCTC lib")
  set(WARPCTC_LIB_RELEASE
      ""
      CACHE FILEPATH "WARPCTC lib")
  list(APPEND mxnet_INCLUDE_DIRS ${WARPCTC_INCLUDE})
  list(APPEND mxnet_LINKER_LIBS ${WARPCTC_LIB})
  file(GLOB_RECURSE PLUGINS_SOURCE "plugin/warpctc/*.cc" "plugin/warpctc/*.h")
  file(GLOB_RECURSE PLUGINS_CUSRC "plugin/warpctc/*.cu")
  list(APPEND SOURCE ${PLUGINS_SOURCE})
  list(APPEND CUDA ${PLUGINS_CUSRC})
endif()

if(USE_PLUGIN_CAFFE)
  if(NOT USE_CUDA)
    set(CPU_ONLY ON)
    list(APPEND mxnet_COMPILE_DEFINITIONS -DCPU_ONLY=1)
  endif()
  if(NOT DEFINED CAFFE_PATH)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/caffe)
      # Need newer FindCUDA.cmake that correctly handles -std=c++11
      cmake_minimum_required(VERSION 3.3)
      set(CAFFE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/caffe)
    else()
      set(CAFFE_PATH $ENV{CAFFE_PATH})
    endif()
  endif()
  list(APPEND CMAKE_MODULE_PATH ${CAFFE_PATH}/cmake)
  list(APPEND mxnet_INCLUDE_DIRS ${CAFFE_PATH}/include ${CAFFE_PATH}/build/src
       ${CMAKE_BINARY_DIR}/caffe/include)
  list(APPEND mxnet_LINK_DIRS ${CAFFE_PATH}/build/lib)
  if(NOT DEFINED CAFFE_PATH)
    message(
      FATAL_ERROR
        "Please set CAFFE_PATH to point to the caffe source installation")
  endif()
  file(GLOB_RECURSE PLUGINS_SOURCE "plugin/caffe/*.cc" "plugin/caffe/*.h")
  file(GLOB_RECURSE PLUGINS_CUSRC "plugin/caffe/*.cu")
  list(APPEND SOURCE ${PLUGINS_SOURCE})
  list(APPEND CUDA ${PLUGINS_CUSRC})
  list(APPEND mxnet_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/include)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_CAFFE=1)
  list(
    APPEND
    mxnet_LINKER_LIBS
    protobuf
    boost_system
    boost_thread
    boost_filesystem
    gflags
    glog
    caffe
    ${Caffe_LINKER_LIBS})

  # unsupported: if caffe is a subdirectory of mxnet, load its CMakeLists.txt as
  # well
  if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/caffe)
    add_subdirectory(caffe)
  endif()
endif(USE_PLUGIN_CAFFE)

# ##############################################################################
# CPP PACKAGE
# ##############################################################################
if(USE_CPP_PACKAGE)
  # For some reason cmake is adding a "-D" to the beggining of this definition
  list(APPEND mxnet_COMPILE_DEFINITIONS MXNET_USE_CPP_PACKAGE=1)
endif()

# ##############################################################################
# EXTRA OPERATORS
# ##############################################################################
if(NOT (EXTRA_OPERATORS STREQUAL ""))
  mxnet_source_group("Extra" GLOB_RECURSE "${EXTRA_OPERATORS}/*.cc")
  mxnet_source_group("Extra\\Cuda" GLOB_RECURSE "${EXTRA_OPERATORS}/*.cu")
  file(GLOB_RECURSE EXTRA_SRC "${EXTRA_OPERATORS}/*.cc")
  file(GLOB_RECURSE EXTRA_CUSRC "${EXTRA_OPERATORS}/*.cu")
  list(APPEND SOURCE ${EXTRA_SRC})
  list(APPEND CUDA ${EXTRA_CUSRC})
endif()

# ##############################################################################
# MXNET LIBRARY
# ##############################################################################

# Add common include directories
list(
  APPEND
  mxnet_INCLUDE_DIRS
  include
  3rdparty/nvidia_cub
  3rdparty/tvm/nnvm/include
  ${CMAKE_BINARY_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Ensure we have no duplicate flags
list(REMOVE_DUPLICATES mxnet_COMPILE_DEFINITIONS)
list(REMOVE_DUPLICATES mxnet_COMPILE_OPTIONS)
list(REMOVE_DUPLICATES mxnet_LINK_DIRS)
list(REMOVE_DUPLICATES mxnet_INCLUDE_DIRS)

foreach(opt in ${mxnet_COMPILE_OPTIONS})
  set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS ${opt})
endforeach()
foreach(def in ${mxnet_COMPILE_DEFINITIONS})
  set_source_files_properties(${SOURCE} PROPERTIES COMPILE_DEFINITIONS ${def})
endforeach()

set(MXNET_INSTALL_TARGETS mxnet)
if(UNIX)
  string(APPEND CMAKE_CUDA_FLAGS "${CUDA_ARCH_FLAGS_SPACES}")

  # Create dummy file since we want an empty shared library before linking
  # set(DUMMY_SOURCE ${CMAKE_BINARY_DIR}/dummy.cc) file(WRITE ${DUMMY_SOURCE}
  # "")

  # add_library(mxnet_static STATIC ${SOURCE} ${CUDA})
  # target_link_libraries(mxnet_static PUBLIC ${CMAKE_DL_LIBS}
  # ${mxnet_LINKER_LIBS}) set_target_properties(mxnet_static PROPERTIES
  # OUTPUT_NAME mxnet) target_include_directories(mxnet_static PUBLIC
  # ${mxnet_INCLUDE_DIRS}) target_link_directories(mxnet_static PUBLIC
  # ${mxnet_LINK_DIRS}) target_compile_definitions(mxnet_static PUBLIC
  # ${mxnet_COMPILE_DEFINITIONS})

  add_library(mxnet SHARED ${SOURCE} ${CUDA})
  # target_link_libraries(mxnet PUBLIC ${CMAKE_DL_LIBS} ${mxnet_LINKER_LIBS})
  # set_target_properties(mxnet PROPERTIES OUTPUT_NAME mxnet)
  # target_include_directories(mxnet PUBLIC ${mxnet_INCLUDE_DIRS})
  # target_link_directories(mxnet PUBLIC ${mxnet_LINK_DIRS})
  # target_compile_definitions(mxnet PUBLIC ${mxnet_COMPILE_DEFINITIONS})

elseif(MSVC)
  if(USE_CUDA)
    if(MSVC)
      if(USE_SPLIT_ARCH_DLL)
        add_executable(gen_warp tools/windowsbuild/gen_warp.cpp)
        add_library(
          mxnet SHARED
          tools/windowsbuild/warp_dll.cpp ${CMAKE_BINARY_DIR}/warp_gen_cpp.cpp
          ${CMAKE_BINARY_DIR}/warp_gen.asm)
        target_link_libraries(mxnet PRIVATE cudart Shlwapi)
        list(GET arch_code_list 0 mxnet_first_arch)
        foreach(arch ${arch_code_list})
          add_library(mxnet_${arch} SHARED ${SOURCE} ${CUDA})
          target_link_libraries(mxnet_${arch} PUBLIC ${mxnet_LINKER_LIBS})
          target_link_options(mxnet_${arch} PUBLIC ${mxnet_LINKER_OPTIONS})
          target_compile_options(
            mxnet_${arch}
            PRIVATE
              "$<$<COMPILE_LANGUAGE:CUDA>:--gpu-architecture=compute_${arch}>")
          target_compile_options(
            mxnet_${arch}
            PRIVATE
              "$<$<COMPILE_LANGUAGE:CUDA>:--gpu-code=sm_${arch},compute_${arch}>"
          )
          target_compile_options(
            mxnet_${arch}
            PRIVATE
              "$<$<AND:$<CONFIG:DEBUG>,$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=-MTd -Gy /bigobj>"
          )
          target_compile_options(
            mxnet_${arch}
            PRIVATE
              "$<$<AND:$<CONFIG:RELEASE>,$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=-MT -Gy /bigobj>"
          )
        endforeach()

        add_custom_command(
          OUTPUT ${CMAKE_BINARY_DIR}/warp_gen_cpp.cpp
                 ${CMAKE_BINARY_DIR}/warp_gen.asm
          COMMAND gen_warp $<TARGET_FILE:mxnet_${mxnet_first_arch}>
          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/
          DEPENDS $<TARGET_FILE:mxnet_${mxnet_first_arch}>)
      else(USE_SPLIT_ARCH_DLL)
        string(REPLACE ";" " " NVCC_FLAGS_ARCH "${NVCC_FLAGS_ARCH}")
        set(CMAKE_CUDA_FLAGS "${CUDA_ARCH_FLAGS_SPACES}")
        add_library(mxnet SHARED ${SOURCE} ${CUDA})
        target_compile_options(
          mxnet
          PRIVATE
            "$<$<AND:$<CONFIG:DEBUG>,$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=-MTd -Gy /bigobj>"
        )
        target_compile_options(
          mxnet
          PRIVATE
            "$<$<AND:$<CONFIG:RELEASE>,$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=-MT -Gy /bigobj>"
        )

      endif(USE_SPLIT_ARCH_DLL)
    else()
      add_library(mxnet SHARED ${SOURCE} ${CUDA})
    endif()
  else()
    add_library(mxnet SHARED ${SOURCE} ${CUDA})
  endif()
endif()

# Link in mshadow and tvmop
target_link_libraries(mxnet PRIVATE ${mxnet_LINKER_LIBS})

# Make sure the mxnet library knows where to find includes
target_include_directories(mxnet PUBLIC ${mxnet_INCLUDE_DIRS})

target_link_directories(mxnet PUBLIC ${mxnet_LINK_DIRS})
target_compile_definitions(mxnet PUBLIC ${mxnet_COMPILE_DEFINITIONS})
target_link_options(mxnet PUBLIC ${mxnet_LINKER_OPTIONS})

# ##############################################################################
# CUSTOM OP LIBRARIES
# ##############################################################################

add_library(
  customop_lib SHARED
  ${CMAKE_CURRENT_SOURCE_DIR}/example/extensions/lib_custom_op/gemm_lib.cc)
target_include_directories(
  customop_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/mxnet
                      ${mxnet_INCLUDE_DIRS})
target_compile_options(customop_lib PUBLIC ${mxnet_COMPILE_OPTIONS})
target_link_directories(customop_lib PUBLIC ${mxnet_LINK_DIRS})
target_compile_definitions(customop_lib PUBLIC ${mxnet_COMPILE_DEFINITIONS})
target_link_options(customop_lib PUBLIC ${mxnet_LINKER_OPTIONS})

add_library(
  subgraph_lib SHARED
  ${CMAKE_CURRENT_SOURCE_DIR}/example/extensions/lib_subgraph/subgraph_lib.cc)
target_include_directories(
  subgraph_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/mxnet
                      ${mxnet_INCLUDE_DIRS})
target_compile_options(subgraph_lib PUBLIC ${mxnet_COMPILE_OPTIONS})
target_link_directories(subgraph_lib PUBLIC ${mxnet_LINK_DIRS})
target_compile_definitions(subgraph_lib PUBLIC ${mxnet_COMPILE_DEFINITIONS})
target_link_options(subgraph_lib PUBLIC ${mxnet_LINKER_OPTIONS})

if(USE_CUDA)
  add_library(
    customop_gpu_lib SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/example/extensions/lib_custom_op/relu_lib.cu)
  target_include_directories(
    customop_gpu_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/mxnet
                            ${mxnet_INCLUDE_DIRS})
  target_link_directories(customop_gpu_lib PUBLIC ${mxnet_LINK_DIRS})
  target_compile_definitions(customop_gpu_lib
                             PUBLIC ${mxnet_COMPILE_DEFINITIONS})
  target_link_options(customop_gpu_lib PUBLIC ${mxnet_LINKER_OPTIONS})
endif()

if(UNIX)
  target_compile_options(customop_lib PUBLIC -shared)
  target_compile_options(subgraph_lib PUBLIC -shared)
  if(USE_CUDA)
    target_compile_options(customop_gpu_lib PUBLIC -shared)
  endif()
elseif(MSVC)
  target_compile_options(customop_lib PUBLIC /LD)
  target_compile_options(subgraph_lib PUBLIC /LD)
  set_target_properties(customop_lib PROPERTIES PREFIX "lib")
  set_target_properties(subgraph_lib PROPERTIES PREFIX "lib")
  if(USE_CUDA)
    target_compile_options(
      customop_gpu_lib PUBLIC "$<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-fPIC>")
    set_target_properties(customop_gpu_lib PROPERTIES PREFIX "lib")
  endif()
endif()

# ##############################################################################
# IM2REC
# ##############################################################################

if(USE_OPENCV AND OpenCV_VERSION_MAJOR GREATER 2)
  add_executable(im2rec "tools/im2rec.cc")
  target_compile_options(im2rec PUBLIC ${mxnet_COMPILE_OPTIONS})
  target_link_directories(im2rec PUBLIC ${mxnet_LINK_DIRS})
  target_compile_definitions(im2rec PUBLIC ${mxnet_COMPILE_DEFINITIONS})
  target_link_libraries(im2rec PUBLIC ${mxnet_LINKER_LIBS} mxnet ${OpenCV_LIBS})
  target_link_options(im2rec PUBLIC ${mxnet_LINKER_OPTIONS})
else()
  message(
    WARNING
      "OpenCV_VERSION_MAJOR: ${OpenCV_VERSION_MAJOR}, version 3 with imgcodecs \
    is required for im2rec, im2rec will not be available")
endif()

if(MSVC AND USE_MXNET_LIB_NAMING)
  set_target_properties(mxnet PROPERTIES OUTPUT_NAME "libmxnet")
endif()

# ##############################################################################
# INSTALL
# ##############################################################################

include(GNUInstallDirs)
install(
  TARGETS ${MXNET_INSTALL_TARGETS}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

# NOTE: Public headers will be installed into
# ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}, see
# https://cmake.org/cmake/help/v3.0/variable/CMAKE_INSTALL_PREFIX.html
# https://cmake.org/cmake/help/v3.0/module/GNUInstallDirs.html

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/dlpack/include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/dmlc-core/include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
if(USE_MKLDNN)
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/mkldnn/include/
          DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
endif()
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/mshadow/mshadow/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mshadow)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/mxnet/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mxnet)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/tvm/nnvm/include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
if(INSTALL_EXAMPLES)
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/example
          DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME})
endif()

if(USE_SIGNAL_HANDLER)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_SIGNAL_HANDLER=1)
endif()

# AUTO_INSTALL_DIR -> Optional: specify post-build install direcory
if(AUTO_INSTALL_DIR)
  # Install Includes
  add_custom_command(
    TARGET mxnet
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/include ${AUTO_INSTALL_DIR}/include)

  # Install Examples
  add_custom_command(
    TARGET mxnet
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_SOURCE_DIR}/example ${AUTO_INSTALL_DIR}/example)
endif()

if(INSTALL_PYTHON_VERSIONS)
  message(STATUS "Installing for python versions: ${INSTALL_PYTHON_VERSIONS}")
  foreach(version ${INSTALL_PYTHON_VERSIONS})
    set(outdir
        ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/python${version}/site-packages/mxnet)
    add_custom_command(
      TARGET mxnet
      POST_BUILD
      COMMAND mkdir -p ${outdir}
      COMMAND cp -ru ${CMAKE_CURRENT_SOURCE_DIR}/python/mxnet/* ${outdir})
  endforeach()
endif()

# ##############################################################################
# CPP PACKAGE
# ##############################################################################
if(USE_CPP_PACKAGE)
  add_subdirectory(cpp-package)
endif()

if(BUILD_CPP_EXAMPLES)
  add_subdirectory(example/image-classification/predict-cpp)
endif()

# ##############################################################################
# TESTS
# ##############################################################################

add_subdirectory(tests)

# ##############################################################################
# LINTER
# ##############################################################################

if(MSVC)
  find_package(PythonInterp)
  set(PYTHON_EXECUTABLE
      ${PYTHON_EXECUTABLE}
      CACHE FILEPATH "Path to the python executable")
endif()

set(LINT_DIRS "include src plugin cpp-package tests")
set(EXCLUDE_PATH "src/operator/contrib/ctc_include")

add_custom_target(
  mxnet_lint
  COMMAND
    ${CMAKE_COMMAND} -DMSVC=${MSVC} -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
    -DLINT_DIRS=${LINT_DIRS} -DPROJECT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -DPROJECT_NAME=mxnet -DEXCLUDE_PATH=${EXCLUDE_PATH} -P
    ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/dmlc-core/cmake/lint.cmake)

# ##############################################################################
# CYTHON MODULES
# ##############################################################################

if(BUILD_CYTHON_MODULES)
  include(cmake/BuildCythonModules.cmake)
  add_cython_modules(3) # Build cython module for python3 if python3 is found
  if((NOT ${PYTHON2_FOUND}) AND (NOT ${PYTHON3_FOUND}))
    message(FATAL_ERROR "No python interpreter found to build cython modules")
  endif()
endif()
