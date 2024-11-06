#!/bin/bash

BUILD_DIR="./build"
mkdir -p $BUILD_DIR

rm -rf $BUILD_DIR/xsim.dir
rm -f $BUILD_DIR/*.log $BUILD_DIR/*.jou $BUILD_DIR/*.pb $BUILD_DIR/*.wdb

echo "\`timescale 1ns/1ps" > $BUILD_DIR/uvm_precompile.sv

cd $BUILD_DIR

# Compile UVM precompile file
xvlog -sv -L uvm uvm_precompile.sv

# Compile package files
xvlog -sv -L uvm ../sim/sim_wb8/wb8_pkg.sv

# Compile interface and DUT files
xvlog -sv -L uvm ../sim/sim_wb8/top_interface.sv
xvlog -sv -L uvm ../rtl/i2c_master_wbs_8.v

xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_wbs_8.v ../rtl/axis_fifo.v
# Compile testbench top
xvlog -sv -L uvm ../sim/sim_wb8/wb8_tb_top.sv

# Elaborate
xelab -L uvm -timescale 1ns/1ps -debug typical wb8_tb_top -s wb8_tb_top

# Run simulation
# xsim -R wb8_tb_top -testplusarg "UVM_VERBOSITY=UVM_LOW"
xsim -R wb8_tb_top -testplusarg "UVM_VERBOSITY=UVM_HIGH"

cd ..
