`ifndef I2C_INTERFACE
`define I2C_INTERFACE

interface i2c_interface(input logic clk);
    logic scl_o, scl_i, scl_t;
    logic sda_o, sda_i, sda_t;

    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        output scl_o, sda_o;
        input  scl_i, scl_t, sda_i, sda_t;
    endclocking

    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        input scl_o, scl_i, scl_t, sda_o, sda_i, sda_t;
    endclocking

    modport driver(clocking driver_cb);
    modport monitor(clocking monitor_cb);
endinterface

`endif
