# ---[ Google Test
if(NOT GTEST_ROOT)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/googletest")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/googletest")
    set(GTEST_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/googletest")
    set(GTEST_BOTH_LIBRARIES gtest gtest_main)
    set(GTEST_FOUND ON)
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/gtest")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/gtest")
    set(GTEST_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/gtest")
    set(GTEST_BOTH_LIBRARIES gtest gtest_main)
    set(GTEST_FOUND ON)
  else()
    find_package(GTest)
  endif()
endif()

if(NOT MSVC)
  set(UNITTEST_STATIC_LINK ON)
endif()

# FIXME MSVC unit test linking issue
if(GTEST_FOUND AND NOT MSVC)
  enable_testing()

  file(GLOB_RECURSE UNIT_TEST_SOURCE "cpp/*.cc" "cpp/*.h")

  set(mxnet_TEST_INCLUDE_DIRS ${mxnet_INCLUDE_DIRS})
  list(APPEND mxnet_TEST_INCLUDE_DIRS ${GTEST_INCLUDE_DIR} cpp/include
       ../cpp-package/include)
  list(REMOVE_DUPLICATES mxnet_TEST_INCLUDE_DIRS)

  if(NOT PRIVATE_RUNTIME_DIR)
    set(PRIVATE_RUNTIME_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
  endif()

  add_executable(${PROJECT_NAME}_unit_tests ${UNIT_TEST_SOURCE})
  set_property(TARGET ${PROJECT_NAME}_unit_tests
               PROPERTY RUNTIME_OUTPUT_DIRECTORY ${PRIVATE_RUNTIME_DIR})
  if(USE_CPP_PACKAGE)
    add_dependencies(${PROJECT_NAME}_unit_tests cpp_package_op_h)
  endif()

  target_compile_options(${PROJECT_NAME}_unit_tests
                         PUBLIC ${mxnet_COMPILE_OPTIONS})
  target_include_directories(${PROJECT_NAME}_unit_tests
                             PUBLIC ${mxnet_TEST_INCLUDE_DIRS})
  target_link_directories(${PROJECT_NAME}_unit_tests PUBLIC ${mxnet_LINK_DIRS})
  target_compile_definitions(${PROJECT_NAME}_unit_tests
                             PUBLIC ${mxnet_COMPILE_DEFINITIONS})
  target_link_libraries(
    ${PROJECT_NAME}_unit_tests PUBLIC ${GTEST_LIBRARY} ${nnvm_LINKER_LIBS}
                                      ${mxnet_LINKER_LIBS} mxnet)
  target_link_options(${PROJECT_NAME}_unit_tests PUBLIC ${mxnet_LINKER_OPTIONS})

  add_test(AllTestsIn${PROJECT_NAME}UnitTests
           ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}_unit_tests)
else()
  message(STATUS "Google Test not found")
endif()
