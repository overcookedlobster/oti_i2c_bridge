`ifndef AXIL_MONITOR
`define AXIL_MONITOR

class axil_monitor extends uvm_monitor;
    virtual axil_if vif;
    uvm_analysis_port #(axil_seq_item) ap;
    
    `uvm_component_utils(axil_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "axil_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            axil_seq_item tr = axil_seq_item::type_id::create("tr");
            collect_transaction(tr);
            ap.write(tr);
        end
    endtask

    task collect_transaction(axil_seq_item tr);
        fork
            begin : write_collection
                axil_seq_item write_tr;
                @(vif.monitor_cb iff vif.monitor_cb.awvalid && vif.monitor_cb.awready);
                write_tr = axil_seq_item::type_id::create("write_tr");
                write_tr.addr = vif.monitor_cb.awaddr;
                write_tr.read = 0;
                
                @(vif.monitor_cb iff vif.monitor_cb.wvalid && vif.monitor_cb.wready);
                write_tr.data = vif.monitor_cb.wdata;
                write_tr.strb = vif.monitor_cb.wstrb;
                
                @(vif.monitor_cb iff vif.monitor_cb.bvalid && vif.monitor_cb.bready);
                
                `uvm_info("AXIL_MON", $sformatf("Collected write transaction: addr=%h data=%h", 
                         write_tr.addr, write_tr.data), UVM_LOW)
                ap.write(write_tr);
            end
            
            begin : read_collection
                axil_seq_item read_tr;
                @(vif.monitor_cb iff vif.monitor_cb.arvalid && vif.monitor_cb.arready);
                read_tr = axil_seq_item::type_id::create("read_tr");
                read_tr.addr = vif.monitor_cb.araddr;
                read_tr.read = 1;
                
                @(vif.monitor_cb iff vif.monitor_cb.rvalid && vif.monitor_cb.rready);
                read_tr.data = vif.monitor_cb.rdata;
                
                `uvm_info("AXIL_MON", $sformatf("Collected read transaction: addr=%h data=%h", 
                         read_tr.addr, read_tr.data), UVM_LOW)
                ap.write(read_tr);
            end
        join_any
        disable fork;
    endtask
endclass

`endif
