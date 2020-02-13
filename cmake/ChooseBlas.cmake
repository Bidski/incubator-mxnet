# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  The ASF licenses this
# file to you under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

set(BLAS
    "Open"
    CACHE STRING "Selected BLAS library")
set_property(CACHE BLAS PROPERTY STRINGS "Atlas;Open;MKL")

if(DEFINED USE_BLAS)
  set(BLAS
      "${USE_BLAS}"
      CACHE STRING "Selected BLAS Library")
else()
  if(USE_MKL_IF_AVAILABLE)
    if(NOT MKL_FOUND)
      find_package(MKL)
    endif()
    if(MKL_FOUND)
      set(BLAS
          "MKL"
          CACHE STRING "Selected BLAS Library")
    endif()
  endif()
endif()

if(BLAS STREQUAL "Atlas" OR BLAS STREQUAL "atlas")
  find_package(Atlas REQUIRED)
  list(APPEND mxnet_INCLUDE_DIRS ${Atlas_INCLUDE_DIR})
  list(APPEND mxnet_LINKER_LIBS ${Atlas_LIBRARIES})
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_MKL=0)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_CBLAS=1)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_BLAS_ATLAS=1)
elseif(BLAS STREQUAL "Open" OR BLAS STREQUAL "open")
  find_package(OpenBLAS REQUIRED)
  list(APPEND mxnet_INCLUDE_DIRS ${OpenBLAS_INCLUDE_DIR})
  list(APPEND mxnet_LINKER_LIBS ${OpenBLAS_LIB})
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_MKL=0)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_CBLAS=1)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_BLAS_OPEN=1)
elseif(BLAS STREQUAL "MKL" OR BLAS STREQUAL "mkl")
  find_package(MKL REQUIRED)
  list(APPEND mxnet_INCLUDE_DIRS ${MKL_INCLUDE_DIR})
  list(APPEND mxnet_LINKER_LIBS ${MKL_LIBRARIES})
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_CBLAS=0)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_MKL=1)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_BLAS_MKL=1)
elseif(BLAS STREQUAL "apple")
  find_package(Accelerate REQUIRED)
  list(APPEND mxnet_INCLUDE_DIRS ${Accelerate_INCLUDE_DIR})
  list(APPEND mxnet_LINKER_LIBS ${Accelerate_LIBRARIES})
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_MKL=0)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMSHADOW_USE_CBLAS=1)
  list(APPEND mxnet_COMPILE_DEFINITIONS -DMXNET_USE_BLAS_APPLE=1)
endif()
