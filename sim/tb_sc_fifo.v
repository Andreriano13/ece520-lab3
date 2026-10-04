`timescale 1ns / 1ps
// tb_sc_fifo.v - self-checking testbench, ECE 520 Lab 3
// Scaffold by Claude (Anthropic), blanks filled in by Andres - cited in README.md
module tb_sc_fifo;
    // same knobs as the FIFO - change these to test Nanas's values (AE 2, AF 30, RL 2)
    parameter WIDTH                  = 16;
    parameter DEPTH                  = 32;
    parameter ALMOST_EMPTY_THRESHOLD = 1;
    parameter ALMOST_FULL_THRESHOLD  = 31;
    parameter READ_LATENCY           = 1;

    // ---- E1: wires and regs that plug into the FIFO ----
    // inputs we DRIVE are reg; outputs we WATCH are wire
    reg              clk = 0;
    reg              srst = 0;
    reg              write_enable = 0;
    reg              read_enable  = 0;
    reg  [WIDTH-1:0] data_in = 0;
    wire [WIDTH-1:0] data_out;
    wire             valid, empty, full, almost_empty, almost_full;
    wire [$clog2(DEPTH+1)-1:0]    data_count;          // BLANK 1: same width as in sc_fifo.v

    // the FIFO under test ("uut" = unit under test)
    sc_fifo #(
        .WIDTH(WIDTH), .DEPTH(DEPTH),
        .ALMOST_EMPTY_THRESHOLD(ALMOST_EMPTY_THRESHOLD),
        .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
        .READ_LATENCY(READ_LATENCY)
    ) uut (
        .clk(clk), .srst(srst),
        .write_enable(write_enable), .read_enable(read_enable),
        .data_in(data_in), .data_out(data_out), .valid(valid),
        .empty(empty), .full(full),
        .almost_empty(almost_empty), .almost_full(almost_full),
        .data_count(data_count)
    );

    // 50 MHz clock: period = 20 ns, so flip every half period
    always #10 clk = ~clk;              // BLANK 2: half of 20 ns

    // the 128 test words your Python script made (4 blocks of 32)
    reg [WIDTH-1:0] stim [0:4*DEPTH-1];
    initial $readmemh("input_data.txt", stim);

    // ---- E2: the scoreboard = a "notebook" of what SHOULD come out, in order ----
    reg [WIDTH-1:0] expected [0:1023];
    integer exp_head = 0, exp_tail = 0;   // tail = where the next write is noted, head = next one to check
    integer errors = 0, checks = 0;

    // note down every write the FIFO actually ACCEPTS
    always @(posedge clk) begin
        if (!srst && write_enable && !full) begin      // BLANK 3: when is a write accepted? (same as wr_ok)
            expected[exp_tail] <= data_in;
            exp_tail <= exp_tail + 1;
        end
    end

    // whenever the FIFO says "this output is real", compare it with the oldest note
    always @(posedge clk) begin
        if (valid) begin                               // BLANK 4: which output means "data_out is good now"?
            checks = checks + 1;
            if (data_out !== expected[exp_head]) begin
                errors = errors + 1;
                $display("FAIL t=%0t: data_out=%h expected=%h", $time, data_out, expected[exp_head]);
            end
            exp_head = exp_head + 1;
        end
    end

    // ---- E3a: helpers (tasks = little reusable routines) ----
    // check one condition; if false, count an error and print what failed
    task check(input cond, input [8*40-1:0] what);
        begin
            checks = checks + 1;
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL t=%0t: %0s", $time, what);
            end
        end
    endtask

    // write one block of 32 words from the Python file, one per clock
    // (we change inputs on the FALLING edge so they are steady at the rising edge)
    task write_block(input integer start);
        integer k;
        begin
            for (k = 0; k < DEPTH; k = k + 1) begin      // BLANK 5: how many words fill the FIFO?
                @(negedge clk);
                write_enable = 1;
                data_in = stim[start + k];
            end
            @(negedge clk);
            write_enable = 0;
        end
    endtask

    // keep reading until the FIFO has nothing left
    task read_all;
        begin
            @(negedge clk);
            read_enable = 1;
            while (!empty) @(negedge clk);               // BLANK 6: which flag means "nothing left"?
            read_enable = 0;
            repeat (READ_LATENCY + 2) @(negedge clk);   // let the last word travel out the runners
        end
    endtask

    // ---- E3b: the test cases (TC0 ... TC6), one story from top to bottom ----
    integer b;
    initial begin
        // TC0: reset - press srst for 3 clocks, everything must go back to zero/empty
        srst = 1;
        repeat (3) @(negedge clk);
        srst = 0;
        @(negedge clk);
        check(data_out == 0,  "TC0 data_out not 0 after reset");   // BLANK 7: what should data_out be after reset?
        check(valid == 0,        "TC0 valid not 0 after reset");
        check(empty == 1,        "TC0 empty not 1 after reset");
        check(full == 0,         "TC0 full not 0 after reset");
        check(data_count == 0,   "TC0 data_count not 0 after reset");

        // TC1-TC4: the 4 blocks from Python (all 1s, all 0s, AAAA/5555, 0..31)
        // each one: fill EVERY slot, try to overflow, read EVERY slot, try to underflow
        for (b = 0; b < 4; b = b + 1) begin
            write_block(b * DEPTH);
            check(full == 1,        "full not set after DEPTH writes");  // BLANK 8: after 32 writes, full = ?
            check(almost_full == 1,    "almost_full not set when full");
            check(data_count == DEPTH, "data_count not DEPTH when full");

            // overflow: writing while full must be ignored (DEAD must never come out)
            @(negedge clk); write_enable = 1; data_in = 16'hDEAD;
            @(negedge clk); write_enable = 0;
            check(data_count == DEPTH, "overflow write changed data_count");

            read_all;
            check(empty == 1,          "empty not set after reading all");
            check(almost_empty == 1,   "almost_empty not set when empty");
            check(data_count == 0,     "data_count not 0 when empty");

            // underflow: reading while empty must be ignored (no valid pulse)
            @(negedge clk); read_enable = 1;
            @(negedge clk); read_enable = 0;
            repeat (READ_LATENCY + 1) @(negedge clk);
            check(valid == 0,          "underflow read produced valid");
        end

        // TC5: almost_empty / almost_full switch at exactly their thresholds
        for (b = 0; b < DEPTH; b = b + 1) begin
            @(negedge clk); write_enable = 1; data_in = b;
            @(negedge clk); write_enable = 0;
            check(almost_empty == (data_count <= ALMOST_EMPTY_THRESHOLD), "almost_empty wrong");
            check(almost_full  == (data_count >= ALMOST_FULL_THRESHOLD),  "almost_full wrong");
        end
        read_all;

        // TC6: write and read in the SAME clock - count must not change
        @(negedge clk); write_enable = 1; data_in = 16'h1234;
        @(negedge clk); write_enable = 1; read_enable = 1; data_in = 16'h5678;
        @(negedge clk); write_enable = 0; read_enable = 0;
        check(data_count == 1, "simultaneous R/W changed count");
        read_all;

        // final score
        if (exp_head != exp_tail) begin
            errors = errors + 1;
            $display("FAIL: %0d writes never came out", exp_tail - exp_head);
        end
        if (errors == 0) $display("PASS: %0d checks, 0 errors (RL=%0d AE=%0d AF=%0d)",
                                  checks, READ_LATENCY, ALMOST_EMPTY_THRESHOLD, ALMOST_FULL_THRESHOLD);
        else             $display("FAIL: %0d errors in %0d checks", errors, checks);
        $finish;
    end

endmodule
