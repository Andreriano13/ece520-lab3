`timescale 1ns / 1ps
// sc_fifo.v - single-clock BRAM FIFO, ECE 520 Lab 3
module sc_fifo #(
    parameter WIDTH                  = 16,
    parameter DEPTH                  = 32,
    parameter ALMOST_EMPTY_THRESHOLD = 1,
    parameter ALMOST_FULL_THRESHOLD  = 31,
    parameter READ_LATENCY           = 1
)(
    input  wire             clk,
    input  wire [WIDTH-1:0] data_in,
    output wire             full,
    
    input wire 	            srst,
    input wire  	    write_enable,
    input wire 	    	    read_enable, 
    output wire  [WIDTH-1:0] data_out,

    output wire              valid,
    output wire              empty,
    output wire              almost_full,
    output wire              almost_empty,
    output wire [$clog2(DEPTH+1)-1:0] data_count
           
);
    localparam ADDR_W = $clog2(DEPTH);      // 5 bits: slot number 0-31
    localparam CNT_W  = $clog2(DEPTH+1);    // 6 bits: count 0-32
    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];        // the 32 clips (BRAM)

    reg [ADDR_W-1:0] wp;
    reg [ADDR_W-1:0] rp;          // same size as wp
    reg [CNT_W-1:0] count;       // the 6-bit size (0-32)
    assign empty = (count == 0);

    assign full         = (count == DEPTH);   // full when count = 32
    assign almost_empty = (count <= ALMOST_EMPTY_THRESHOLD);   // the parameter name from the top
    assign almost_full  = (count >= ALMOST_FULL_THRESHOLD);   // the parameter name from the top

    wire wr_ok = write_enable && !full;
    wire rd_ok = read_enable  && !empty;

    always @(posedge clk) begin
        if (srst) begin
            wp    <= 0;
            rp    <= 0;
            count <= 0;
        end else begin
            if (wr_ok) wp <= wp + 1;     // ticket clipped -> wp moves
            if (rd_ok) rp <= rp + 1;       // ticket cooked -> rp moves
            case ({wr_ok, rd_ok})
                2'b10:   count <= count + 1;   // only in
                2'b01:   count <= count - 1;   // only out
                default: count <= count;       // both or neither
            endcase
        end
    end
    
    reg [WIDTH-1:0] dpipe [0:READ_LATENCY-1];   // data runners (stage 0 = BRAM output register)
    reg             vpipe [0:READ_LATENCY-1];   // valid runners, travel with the data
    integer i;

    // write side: clip the ticket into its slot
    always @(posedge clk) begin
        if (wr_ok) mem[wp] <= data_in;
    end

    // read side: stage 0 grabs the oldest ticket, later stages pass it along (spec 2.8)
    always @(posedge clk) begin
        if (srst) begin
            for (i = 0; i < READ_LATENCY; i = i + 1) begin
                dpipe[i] <= 0;
                vpipe[i] <= 0;
            end
        end else begin
            vpipe[0] <= rd_ok;                     // valid only after a good read
            if (rd_ok) dpipe[0] <= mem[rp];        // grab the oldest ticket
            for (i = 1; i < READ_LATENCY; i = i + 1) begin
                dpipe[i] <= dpipe[i-1];            // each runner takes from the one before
                vpipe[i] <= vpipe[i-1];
            end
        end
    end

    // --- YOUR TURN: connect the outputs (replace each ____) ---
    assign data_out   = dpipe[READ_LATENCY-1];   // the LAST runner (index = READ_LATENCY-1)
    assign valid      = vpipe[READ_LATENCY-1];   // same last runner
    assign data_count = count;          // the counter you made in D2
endmodule
