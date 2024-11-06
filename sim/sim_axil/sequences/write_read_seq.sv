`ifndef WRITE_READ_SEQ
`define WRITE_READ_SEQ

class write_read_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(write_read_seq)
    
    function new(string name = "write_read_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;
        bit [6:0] slave_addr = 7'h50;
        bit [7:0] reg_addr = 8'h0;
        bit [7:0] data_to_write = 8'hA5;
		
		memory_slave_seq mem_slave = memory_slave_seq::type_id::create("req");
		api_single_rw_seq api_rw = api_single_rw_seq::type_id::create("req");

		int timeout_count = 0;

        `uvm_info("SEQ", "Starting I2C write/read sequence", UVM_MEDIUM)
        mem_slave.configure(m_sequencer, slave_addr);
		api_rw.configure(m_sequencer);
		
		mem_slave.register_write(reg_addr, data_to_write); // WRITE TO I2C SLAVE
        
    do begin
        api_rw.read_register_status();
        `uvm_info("SEQ", $sformatf("Status register: %h", api_rw.rsp.data), UVM_HIGH)
        
        // Add timeout check
        timeout_count++;
        if (timeout_count >= 1000) begin
            `uvm_error("SEQ", "I2C transaction timeout")
            break;
        end
        
        // Check for error bits in status
        // if (api_rw.rsp.data[/* error bit */]) begin
        //     `uvm_error("SEQ", "I2C transaction error detected")
        //     break;
        // end
    end while (api_rw.rsp.data[0]); // Wait until not busy
        
		// READ TO I2C SLAVE
		mem_slave.register_read(reg_addr);
        
		`uvm_info("SEQ", $sformatf("Read data from I2C: %h", mem_slave.data), UVM_LOW)
    endtask
endclass

`endif
