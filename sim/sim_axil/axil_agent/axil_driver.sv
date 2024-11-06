`ifndef AXIL_DRIVER
`define AXIL_DRIVER

class axil_driver extends uvm_driver #(axil_seq_item);
    virtual axil_if vif;  // Make sure this matches your interface type
    
    `uvm_component_utils(axil_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "axil_vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface not found for %s", get_full_name()))
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
			$cast(rsp,req.clone());
			rsp.set_id_info(req);
            seq_item_port.item_done();
			seq_item_port.put(rsp);
        end
    endtask

    task drive_transaction(axil_seq_item req);
        if(req.read) begin
            @(vif.driver_cb);
            vif.driver_cb.araddr <= req.addr;
            vif.driver_cb.arvalid <= 1;
            vif.driver_cb.arprot <= 0;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.arready) @(vif.driver_cb);
            vif.driver_cb.arvalid <= 0;
            
            vif.driver_cb.rready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.rvalid) @(vif.driver_cb);
            req.data = vif.driver_cb.rdata;
            vif.driver_cb.rready <= 0;
        end else begin
            @(vif.driver_cb);
            vif.driver_cb.awaddr <= req.addr;
            vif.driver_cb.awvalid <= 1;
            vif.driver_cb.awprot <= 0;
            vif.driver_cb.wdata <= req.data;
            vif.driver_cb.wstrb <= req.strb;
            vif.driver_cb.wvalid <= 1;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.awready || !vif.driver_cb.wready) @(vif.driver_cb);
            vif.driver_cb.awvalid <= 0;
            vif.driver_cb.wvalid <= 0;
            
            vif.driver_cb.bready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.bvalid) @(vif.driver_cb);
            vif.driver_cb.bready <= 0;
        end
    endtask
endclass

`endif
