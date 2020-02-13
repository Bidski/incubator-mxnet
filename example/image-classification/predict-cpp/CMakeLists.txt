# Check OpenCV
if(NOT USE_OPENCV
   OR NOT OpenCV_FOUND
   OR OpenCV_VERSION_MAJOR LESS 3)
  message(
    WARNING
      "\
OpenCV version >= 3 should be enabled and found to build image classification example, skipping..."
  )
  return()
endif()

add_executable(image-classification-predict image-classification-predict.cc)
target_link_libraries(image-classification-predict ${nnvm_LINKER_LIBS}
                      ${mxnet_LINKER_LIBS} mxnet)
target_include_directories(image-classification-predict
                           PUBLIC ${mxnet_INCLUDE_DIRS} ${OpenCV_INCLUDE_DIRS})
target_link_directories(image-classification-predict PUBLIC ${mxnet_LINK_DIRS})
target_compile_options(image-classification-predict
                       PUBLIC ${mxnet_COMPILE_OPTIONS})
target_compile_definitions(image-classification-predict
                           PUBLIC ${mxnet_COMPILE_DEFINITIONS})
target_link_options(image-classification-predict PUBLIC ${mxnet_LINKER_OPTIONS})
add_dependencies(image-classification-predict mxnet)
