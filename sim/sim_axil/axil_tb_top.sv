`ifndef AXIL_TB_TOP
`define AXIL_TB_TOP

`include "../common/i2c_interface.sv"
`include "axil_interface.sv"
`include "dut_params_defines.svh"

module axil_tb_top;
	import uvm_pkg::*;
	import axil_test_pkg::*;
	// import bridge_env_pkg::*;
    
    reg clk;
    reg rst;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        #100;
        rst = 0;
    end
    
    i2c_interface  i2c_if(clk);
    axil_if axil_vif(clk, rst);

	// copied this from the documentation
	assign scl_dut_i = scl_dut_o & scl_tb_o;
	assign scl_tb_i = scl_dut_o & scl_tb_o;
	assign sda_dut_i = sda_dut_o & sda_tb_o;
	assign sda_tb_i = sda_dut_o & sda_tb_o;
	
	// connect the above logic to the interface
	assign scl_tb_o = i2c_if.scl_o; 
	assign sda_tb_o = i2c_if.sda_o;
	assign i2c_if.scl_i = scl_tb_i;
	assign i2c_if.sda_i = sda_tb_i;

    i2c_master_axil #(
        .DEFAULT_PRESCALE(DEFAULT_PRESCALE),
        .FIXED_PRESCALE(FIXED_PRESCALE),
        .CMD_FIFO(CMD_FIFO),
        .CMD_FIFO_DEPTH(CMD_FIFO_DEPTH),
        .WRITE_FIFO(WRITE_FIFO),
        .WRITE_FIFO_DEPTH(WRITE_FIFO_DEPTH),
        .READ_FIFO(READ_FIFO),
        .READ_FIFO_DEPTH(READ_FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .s_axil_awaddr(axil_vif.awaddr),
        .s_axil_awprot(axil_vif.awprot),
        .s_axil_awvalid(axil_vif.awvalid),
        .s_axil_awready(axil_vif.awready),
        .s_axil_wdata(axil_vif.wdata),
        .s_axil_wstrb(axil_vif.wstrb),
        .s_axil_wvalid(axil_vif.wvalid),
        .s_axil_wready(axil_vif.wready),
        .s_axil_bresp(axil_vif.bresp),
        .s_axil_bvalid(axil_vif.bvalid),
        .s_axil_bready(axil_vif.bready),
        .s_axil_araddr(axil_vif.araddr),
        .s_axil_arprot(axil_vif.arprot),
        .s_axil_arvalid(axil_vif.arvalid),
        .s_axil_arready(axil_vif.arready),
        .s_axil_rdata(axil_vif.rdata),
        .s_axil_rresp(axil_vif.rresp),
        .s_axil_rvalid(axil_vif.rvalid),
        .s_axil_rready(axil_vif.rready),
		
        .i2c_scl_i(scl_dut_i),
        .i2c_scl_o(scl_dut_o),
        .i2c_scl_t(i2c_if.scl_t),
        .i2c_sda_i(sda_dut_i),
        .i2c_sda_o(sda_dut_o),
        .i2c_sda_t(i2c_if.sda_t)
    );

	initial begin
		uvm_config_db#(virtual i2c_interface)::set(null, "*", "i2c_vif", i2c_if);
		uvm_config_db#(virtual axil_if)::set(null, "*", "axil_vif", axil_vif);

		run_test("i2c_master_test");
	end


    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, axil_tb_top);
    end

endmodule

`endif
