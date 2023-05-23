#!/bin/bash
#set -x

# Overall steps:
# Make sure you have these resources:
#   >> arc shell coverity/2022.03.01 intel_opae boost gcc/9.3.0 cmake/3.15.4
#
# Build MPF, install MPF library
# To use the library, add installation library directory to the environment
#  >> cd BBB_cci_mpf/sw/
#  >> mkdir build && cd build
#  >> cmake ..
#  >> make install DESTDIR=intel-fpga-bbb/BBB_cci_mpf/install_mpf
#
# Build necessary examples, tests, etc
# For boost library:
#   In the following file: BBB_cci_mpf/test/test-mpf/base/sw/base_include.mk, add to CPPFLAGS the boost resource
#       ifneq (,$(BOOST_ROOT))
#       CPPFLAGS += -I${BOOST_ROOT}/include
#       LDFLAGS += -L$(BOOST_ROOT)/lib
#       endif

top_level_dir=${PWD}

# Configure coverity run
cov-configure -gcc --config output.xml

# Build and install MPF library
cd BBB_cci_mpf/sw
mkdir build && cd build
cmake ..
make
# This installs the library under ${top_level_dir}/BBB_cci_mpf/install_mpf/usr/local 
make install DESTDIR=${top_level_dir}/BBB_cci_mpf/install_mpf

# Add installation library directory to environment shell
export CPATH=${top_level_dir}/BBB_cci_mpf/install_mpf/usr/local/include:$CPATH
export LIBRARY_PATH=${top_level_dir}/BBB_cci_mpf/install_mpf/usr/local/lib64:$LIBRARY_PATH


cd ${top_level_dir}


# Find all examples to build
# Run coverity while building examples
for i in $(find . -name "Makefile" -type f)
do (
  cd $(dirname $(realpath $i));
  echo "Script executed from: ${PWD}"
  echo "cov-build --config ${top_level_dir}/output.xml --dir ${top_level_dir}/coverity_results make"
  #make
  cov-build --config ${top_level_dir}/output.xml --dir ${top_level_dir}/coverity_results make
)
done

cd ${top_level_dir}

# Run coverity analysis
cov-analyze --config output.xml --dir coverity_results --concurrency --security --rule --enable-constraint-fpp --enable-fnptr --enable-virtual
