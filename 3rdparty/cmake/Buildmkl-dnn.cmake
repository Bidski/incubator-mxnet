include(ExternalProject)

if(NOT USE_OPENMP)
  set(MKLDNN_CPU_RUNTIME "-DDNNL_CPU_RUNTIME=SEQ")
else()
  set(MKLDNN_CPU_RUNTIME "")
endif()

ExternalProject_Add(
  mkldnn
  GIT_REPOSITORY "https://github.com/intel/mkl-dnn.git"
  GIT_TAG "cb2cc7a"
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/mkldnn
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=lib
             -DBUILD_SHARED_LIBS=ON
             -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
             -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
             -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
             -DDNNL_CPU_THREADING_RUNTIME=SEQ
             -DDNNL_BUILD_TESTS=OFF
             -DDNNL_BUILD_EXAMPLES=OFF
             -DDNNL_ENABLE_JIT_PROFILING=OFF
             -DDNNL_LIBRARY_TYPE=STATIC
             ${MKLDNN_CPU_RUNTIME}
  BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
  TEST_COMMAND "")
