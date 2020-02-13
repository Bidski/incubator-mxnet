if(NOT MSVC)
  set(UNITTEST_STATIC_LINK ON)
endif(NOT MSVC)

set(CPP_EXAMPLE_LIBS ${mxnet_LINKER_LIBS} mxnet)

set(CPP_PACKAGE_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/../include/mxnet-cpp/)

set(CPPEX_DEPS cpp_package_op_h)

file(GLOB_RECURSE CPP_PACKAGE_HEADERS "${CPP_PACKAGE_INCLUDE_DIR}/*.h"
     "${CPP_PACKAGE_INCLUDE_DIR}/*.hpp")

if(MSVC)
  add_custom_target(
    cpp_package_deploy_library ALL
    DEPENDS mxnet
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:mxnet>
            $<TARGET_FILE_DIR:mlp>)
endif()

set(mxnet_CPP_INCLUDE_DIRS ${mxnet_INCLUDE_DIRS})
list(APPEND mxnet_CPP_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/../include)
list(REMOVE_DUPLICATES mxnet_CPP_INCLUDE_DIRS)

# Create an executable for each exmaple
set(CPP_EXAMPLES
    test_regress_label
    lenet
    lenet_with_mxdataiter
    alexnet
    charRNN
    googlenet
    inception_bn
    mlp
    mlp_cpu
    mlp_gpu
    resnet)

foreach(cpp_example ${CPP_EXAMPLES})
  add_executable(${cpp_example} ${cpp_example}.cpp ${CPP_PACKAGE_HEADERS})
  target_link_libraries(${cpp_example} ${CPP_EXAMPLE_LIBS})
  target_include_directories(${cpp_example} PUBLIC ${mxnet_CPP_INCLUDE_DIRS})
  target_link_directories(${cpp_example} PUBLIC ${mxnet_LINK_DIRS})
  target_compile_options(${cpp_example} PUBLIC ${mxnet_COMPILE_OPTIONS})
  target_compile_definitions(${cpp_example} PUBLIC ${mxnet_COMPILE_DEFINITIONS})
  target_link_options(${cpp_example} PUBLIC ${mxnet_LINKER_OPTIONS})
  add_dependencies(${cpp_example} ${CPPEX_DEPS})
endforeach()
