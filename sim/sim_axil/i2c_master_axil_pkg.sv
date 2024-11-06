`ifndef I2C_MASTER_AXIL_PKG
`define I2C_MASTER_AXIL_PKG

package i2c_master_axil_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	import dut_params_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "reg_defines.svh"

endpackage

`endif


