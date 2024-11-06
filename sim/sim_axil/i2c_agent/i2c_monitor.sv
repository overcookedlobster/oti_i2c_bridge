`ifndef I2C_MONITOR
`define I2C_MONITOR

class i2c_monitor extends uvm_monitor;
    virtual i2c_if vif;
    uvm_analysis_port #(i2c_trans) ap;
    
    `uvm_component_utils(i2c_monitor)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task wait_for_start();
        @(negedge vif.sda_o iff vif.scl_o === 1);  
        `uvm_info("I2C_MON", "START condition detected", UVM_HIGH)
    endtask

    
    task receive_byte(output bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            // Should check both sda_o and sda_i depending on who's driving
            data[i] = vif.sda_t ? vif.sda_i : vif.sda_o;

                `uvm_info("I2C_MON", $sformatf("Bit[%0d]=%b at time %0t", i, data[i], $time), UVM_HIGH)
            wait(!vif.scl_o);
        end
    endtask
    task receive_byte_with_stop(output bit [7:0] data, output bit is_stop);
        is_stop = 0;
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            data[i] = vif.sda_o;

            // Detect stop condition
            if ((i == 7) && !vif.sda_o) begin
                wait(!vif.scl_o || vif.sda_o);
                if (vif.sda_o) begin
                    is_stop = 1;
                    `uvm_info("I2C_MON", "Stop condition detected", UVM_HIGH)
                    break;
                end
            end
            
            wait(!vif.scl_o);
        end
    endtask

    task monitor_ack();
        @(posedge vif.scl_o);
        // Check based on who's driving (master or slave)
        if (vif.sda_t ? vif.sda_i : vif.sda_o)
            `uvm_info("I2C_MON", "NACK received", UVM_HIGH)
        else
            `uvm_info("I2C_MON", "ACK received", UVM_HIGH)
        wait(!vif.scl_o);
    endtask

    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] data_byte;
        bit is_stop;
        
        forever begin
            i2c_trans trans;
            
            wait_for_start();
            trans = i2c_trans::type_id::create("trans");
            
            // Address Phase
            receive_byte(addr_byte);
            `uvm_info("I2C_MON", $sformatf("Address Phase: 0x%02h [%s]", 
                addr_byte[7:1], addr_byte[0] ? "READ" : "WRITE"), UVM_HIGH)
            
            monitor_ack();
            
            trans.addr = addr_byte[7:1];
            trans.read = addr_byte[0];
            
            // Data Phase
            if (trans.read) begin
                // Read Operation
                do begin
                    receive_byte_with_stop(data_byte, is_stop);
                    if (!is_stop) begin
                        trans.data = data_byte;
                        `uvm_info("I2C_MON", 
                            $sformatf("Read Data: 0x%02h from addr 0x%02h", 
                            data_byte, trans.addr), UVM_HIGH)
                        monitor_ack();
                        ap.write(trans);
                    end
                end while (!is_stop);
            end else begin
                // Write Operation
                receive_byte_with_stop(data_byte, is_stop);
                while (!is_stop) begin
                    trans.data = data_byte;
                    `uvm_info("I2C_MON", 
                        $sformatf("Write Data: 0x%02h to addr 0x%02h", 
                        data_byte, trans.addr), UVM_HIGH)
                    monitor_ack();
                    ap.write(trans);
                    receive_byte_with_stop(data_byte, is_stop);
                end
            end
        end
    endtask
endclass

`endif
