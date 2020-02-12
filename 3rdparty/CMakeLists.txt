cmake_minimum_required(VERSION 3.13)

project(mxnet_3rdparty LANGUAGES C CXX)
message(
  STATUS "CMake version '${CMAKE_VERSION}' using generator '${CMAKE_GENERATOR}'"
)

#
# Change the default build type from Debug to Release, while still supporting
# overriding the build type.
#
# The CACHE STRING logic here and elsewhere is needed to force CMake to pay
# attention to the value of these variables.
if(NOT CMAKE_BUILD_TYPE)
  message(
    STATUS "No build type specified; defaulting to CMAKE_BUILD_TYPE=Release.")
  set(CMAKE_BUILD_TYPE
      Release
      CACHE
        STRING
        "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
        FORCE)
else(NOT CMAKE_BUILD_TYPE)
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(
      "=========================================================================================="
    )
    message(STATUS "Build type: Debug. Performance will be terrible!")
    message(
      STATUS
        "Add -DCMAKE_BUILD_TYPE=Release to the CMake command line to get an optimized build."
    )
    message(
      "=========================================================================================="
    )
  endif(CMAKE_BUILD_TYPE STREQUAL "Debug")
endif(NOT CMAKE_BUILD_TYPE)

if(USE_CUDA)
  # CUDA 10 (Turing) detection available starting 3.13.2
  cmake_minimum_required(VERSION 3.13.2)
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
  find_package(CUDA REQUIRED)
endif()

if(UNIX)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
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

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX
      ${CMAKE_SOURCE_DIR}/../build
      CACHE PATH "Install path prefix, prepended onto install directories."
            FORCE)
endif()

message(STATUS "CMAKE_CROSSCOMPILING ${CMAKE_CROSSCOMPILING}")
message(STATUS "CMAKE_HOST_SYSTEM_PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_SYSTEM_PROCESSOR ${CMAKE_SYSTEM_PROCESSOR}")

message(STATUS "CMAKE_SYSTEM_NAME ${CMAKE_SYSTEM_NAME}")

if("$ENV{VERBOSE}" STREQUAL "1")
  message(STATUS " Verbose Makefile ACTIVATED")
  set(CMAKE_VERBOSE_MAKEFILE ON)
endif()

# Some things have order. This must be put in front alone
option(USE_CUDA "Build with CUDA support" ON)

# one could set CUDNN_ROOT for search path
option(USE_CUDNN "Build with cudnn support" ON)

# autodetects support if ON
option(USE_F16C "Build with x86 F16C instruction support" ON)

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

option(USE_DIST_KVSTORE "Build with DIST_KVSTORE support" OFF)
option(USE_CXX14_IF_AVAILABLE "Build with C++14 if the compiler supports it"
       OFF)

option(USE_TVM_OP "Enable use of TVM operator build system." OFF)
option(USE_TENSORRT "Enable inference optimization with TensorRT." OFF)

# ##############################################################################
# SET COMPILER OPTIONS
# ##############################################################################

# Check for SSE support
include("cmake/FindSSE.cmake")

set(DEFINITIONS "")

if(MSVC)
  set(DEFINITIONS "${DEFINITIONS} -DWIN32_LEAN_AND_MEAN")
  set(DEFINITIONS "${DEFINITIONS} -DDMLC_USE_CXX11")
  set(DEFINITIONS "${DEFINITIONS} -D_SCL_SECURE_NO_WARNINGS")
  set(DEFINITIONS "${DEFINITIONS} -D_CRT_SECURE_NO_WARNINGS")
  set(DEFINITIONS "${DEFINITIONS} -DMXNET_EXPORTS")
  set(DEFINITIONS "${DEFINITIONS} -DNNVM_EXPORTS")
  set(DEFINITIONS "${DEFINITIONS} -DDMLC_STRICT_CXX11")
  set(DEFINITIONS "${DEFINITIONS} -DNOMINMAX")
  set(CMAKE_C_FLAGS "/MP")
  set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} /bigobj")
else()
  # Check available compiler standard flags
  include(CheckCXXCompilerFlag)
  if(USE_CXX14_IF_AVAILABLE)
    check_cxx_compiler_flag("-std=c++14" SUPPORT_CXX14)
  endif()
  check_cxx_compiler_flag("-std=c++11" SUPPORT_CXX11)
  check_cxx_compiler_flag("-std=c++0x" SUPPORT_CXX0X)

  set(CMAKE_C_FLAGS
      "${CMAKE_C_FLAGS} -Wall -Wno-unknown-pragmas -Wno-sign-compare")

  if("${CMAKE_CXX_COMPILER_ID}" MATCHES ".*Clang$")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-braced-scalar-init")
  endif()

  if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL
                                          "RelWithDebInfo")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_ASSERTIONS")
  endif()

  if(SUPPORT_CXX14)
    set(DEFINITIONS "${DEFINITIONS} -DDMLC_USE_CXX11")
    set(DEFINITIONS "${DEFINITIONS} -DDMLC_USE_CXX14")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
  elseif(SUPPORT_CXX11)
    set(DEFINITIONS "${DEFINITIONS} -DDMLC_USE_CXX11")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  elseif(SUPPORT_CXX0X)
    set(DEFINITIONS "${DEFINITIONS} -DDMLC_USE_CXX11")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
  endif()
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99")
endif(MSVC)

if(MSVC)
  foreach(flag_var
          CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
          CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
    if(${flag_var} MATCHES "/MD")
      string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endif(${flag_var} MATCHES "/MD")
  endforeach(flag_var)
endif()

if(MSVC)
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /EHsc")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /EHsc /Gy")
  set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} /EHsc /Gy")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO
      "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /EHsc /Gy")
  set(CMAKE_SHARED_LINKER_FLAGS_RELEASE
      "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /OPT:REF /OPT:ICF")
  set(CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL
      "${CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL} /OPT:REF /OPT:ICF")
  set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO
      "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} /OPT:REF /OPT:ICF")
endif()

# ##############################################################################
# BUILD THIRD PARTY DEPENDENCIES
# ##############################################################################

# TVM Op
include(${CMAKE_SOURCE_DIR}/cmake/Buildtvm.cmake)

# ONNX TensorRT
if(USE_TENSORRT)
  include(${CMAKE_SOURCE_DIR}/cmake/Buildonnx-tensorrt.cmake)
endif()

# DNNL
if(USE_MKLDNN)
  # CPU architecture (e.g., C5) can't run on another architecture (e.g., g3).
  if(MSVC)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /EHsc /MT")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /EHsc /Gy /MT")
  endif()

  include(${CMAKE_SOURCE_DIR}/cmake/Buildmkl-dnn.cmake)
endif()

# DLPACK
include(${CMAKE_SOURCE_DIR}/cmake/Builddlpack.cmake)

# DMLC
include(${CMAKE_SOURCE_DIR}/cmake/Builddmlc-core.cmake)

# PS-LITE
if(USE_DIST_KVSTORE)
  include(${CMAKE_SOURCE_DIR}/cmake/Buildps-lite.cmake)
endif()

# OPENMP
if(USE_OPENMP)
  find_package(OpenMP REQUIRED)
  if(NOT OPENMP_FOUND)
    # This should build on Windows, but there's some problem and I don't have a
    # Windows box, so could a Windows user please fix?
    if(SYSTEM_ARCHITECTURE STREQUAL "x86_64"
       AND NOT CMAKE_BUILD_TYPE STREQUAL "Distribution"
       AND NOT MSVC
       AND NOT CMAKE_CROSSCOMPILING)
      # Intel/llvm OpenMP: https://github.com/llvm-mirror/openmp
      include(${CMAKE_SOURCE_DIR}/cmake/Buildopenmp.cmake)
    endif()
  endif(NOT OPENMP_FOUND)
endif(USE_OPENMP)

# CTEST AND GOOGLETEST
include(${CMAKE_SOURCE_DIR}/cmake/Buildgoogletest.cmake)
