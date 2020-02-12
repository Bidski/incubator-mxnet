include(ExternalProject)

ExternalProject_Add(
  pslite
  GIT_REPOSITORY "https://github.com/dmlc/ps-lite"
  GIT_TAG "f601054"
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  SOURCE_DIR ${CMAKE_SOURCE_DIR}/ps-lite
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=lib
             -DBUILD_SHARED_LIBS=ON
             -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
             -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
             -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
  BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  INSTALL_COMMAND ""
  TEST_COMMAND "")

ExternalProject_Get_Property(pslite SOURCE_DIR BINARY_DIR)

ExternalProject_Add_Step(
  pslite install_pslite
  COMMAND ${CMAKE_COMMAND} -E echo "Installing pslite"
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX}/include
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX}/lib
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${SOURCE_DIR}/include
          ${CMAKE_INSTALL_PREFIX}/include
  COMMAND ${CMAKE_COMMAND} -E copy "${BINARY_DIR}/libpslite.so"
          ${CMAKE_INSTALL_PREFIX}/lib
  DEPENDEES build)
