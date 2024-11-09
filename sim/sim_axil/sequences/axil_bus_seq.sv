`ifndef AXIL_BUS_SEQ
`define AXIL_BUS_SEQ

class axil_bus_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(axil_bus_seq)
	axil_seq_item req;
	bit is_write;

    function new(string name = "axil_bus_seq");
        super.new(name);
        req = axil_seq_item::type_id::create("req");
    endfunction

    task body();
        start_item(req);
		if (!req.randomize() with {
			req.read == !is_write;
			req.strb == 4'b0011;
		})
			`uvm_error(get_type_name(), "Randomization failed")
        finish_item(req);
		get_response(rsp);
    endtask

endclass

`endif
