include(ExternalProject)

# Switch off modern thread local for dmlc-core, please see:
# https://github.com/dmlc/dmlc-core/issues/571#issuecomment-543467484
set(DEFINITIONS "${DEFINITIONS} -DDMLC_MODERN_THREAD_LOCAL=0")
# disable stack trace in exception by default.
set(DEFINITIONS "${DEFINITIONS} -DDMLC_LOG_STACK_TRACE_SIZE=0")
set(DEFINITIONS "${DEFINITIONS} -DDMLC_LOG_FATAL_THROW=1")

set(CXX_FLAGS "${CMAKE_CXX_FLAGS} ${DEFINITIONS}")

ExternalProject_Add(
  dmlccore
  GIT_REPOSITORY "https://github.com/dmlc/dmlc-core.git"
  GIT_TAG "b3a4c71"
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/dmlc-core
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=lib
             -DBUILD_SHARED_LIBS=ON
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
             -DCMAKE_CXX_FLAGS=${CXX_FLAGS}
             -DUSE_OPENMP=${USE_OPENMP}
             -DUSE_CXX14_IF_AVAILABLE=${USE_CXX14_IF_AVAILABLE}
             -DSUPPORT_MSSE2=${SSE2_FOUND}
  BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
  TEST_COMMAND "")
