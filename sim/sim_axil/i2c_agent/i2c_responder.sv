`ifndef I2C_RESPONDER
`define I2C_RESPONDER

class i2c_responder extends uvm_component;
    virtual i2c_if vif;
    bit [7:0] memory[bit [7:0]]; // Simple memory model
    bit [6:0] my_address;
    
    `uvm_component_utils(i2c_responder)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        my_address = 7'h50; // Default address
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Failed to get I2C virtual interface")
    endfunction
    
    task monitor_start_condition();
        @(negedge vif.sda_o iff vif.scl_o === 1);  
        `uvm_info("I2C_RESP", "START condition detected", UVM_MEDIUM)
    endtask
    
    task receive_byte(output bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            data[i] = vif.sda_o;
            `uvm_info("I2C_RESP", $sformatf("[%t] received bit %d = %d", $time, i, data[i]), UVM_HIGH)
			wait (!vif.scl_o);
        end
    endtask
    
    task receive_byte_with_stop(output bit [7:0] data, output bit is_stop);
		is_stop = 0;
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            data[i] = vif.sda_o;

			// detect stop condition
			if ((i == 7) & !vif.sda_o) begin
				wait (!vif.scl_o | vif.sda_o);
				if (vif.sda_o) begin
					is_stop = 1;
            		`uvm_info(get_type_name(), "stop bit detected", UVM_MEDIUM)
					break;
				end
			end

            `uvm_info(get_type_name(), $sformatf("[%t] bit %d = %d", $time, i, data[i]), UVM_HIGH)
			wait (!vif.scl_o);
        end
    endtask
    
    task send_ack();
		repeat (6) @(vif.clk);
        vif.sda_i <= 0;  // ACK
        wait (vif.scl_o);
        wait (!vif.scl_o);
		repeat (3) @(vif.clk);
        vif.sda_i <= 1;  // Return to high
    endtask

    task send_byte(bit [7:0] data);
        `uvm_info("I2C_RESP", "send byte start", UVM_HIGH)
        for(int i = 7; i >= 0; i--) begin
            vif.sda_i <= data[i];
            `uvm_info("I2C_RESP", $sformatf("[%t] sent bit %d = %d", $time, i, data[i]), UVM_HIGH)
            wait (vif.scl_o);
            wait (!vif.scl_o);
        end
        vif.sda_i <= 1;  // Return to high
    endtask

    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] reg_byte;
        bit [7:0] data_byte;
		bit is_write;
		bit is_stop;
        
        vif.sda_i <= 1;  
        vif.scl_i <= 1;  
        
        forever begin
            monitor_start_condition();
            
            receive_byte(addr_byte);
            
            if((addr_byte[7:1] == my_address)) begin
                send_ack();
				is_write = !addr_byte[0];

				if (is_write) begin
					receive_byte(reg_byte);
					send_ack();
					
					receive_byte_with_stop(data_byte, is_stop);

					while (!is_stop) begin
						memory[reg_byte] = data_byte;
						send_ack();
						`uvm_info("I2C_RESP", $sformatf("Received data: %h", data_byte), UVM_LOW)
						reg_byte++;
						receive_byte_with_stop(data_byte, is_stop);
					end
				end
				else begin
					send_byte(memory[reg_byte]);
					`uvm_info("I2C_RESP", $sformatf("Send data: %h", memory[reg_byte]), UVM_LOW)
				end
            end
        end
    endtask

    // Utility functions to set/get memory values
    function void set_memory(bit [6:0] addr, bit [7:0] data);
        memory[addr] = data;
    endfunction
    
    function bit [7:0] get_memory(bit [6:0] addr);
        return memory[addr];
    endfunction
endclass

`endif
