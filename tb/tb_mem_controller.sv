`timescale 1ns/1ps

module tb_mem_controller;

  localparam int ADDR_W         = 5;
  localparam int DEPTH_WORDS    = 8;
  localparam int LATENCY_CYCLES = 3;

  logic        clk;
  logic        rst_n;

  logic        req_valid;
  logic        req_rw;       // 0=read, 1=write
  logic [31:0] req_addr;
  logic [31:0] req_wdata;

  logic        resp_ready;
  logic [31:0] resp_rdata;
  int unsigned error_count;

  mem_controller #(
    .ADDR_W(ADDR_W),
    .DEPTH_WORDS(DEPTH_WORDS),
    .LATENCY_CYCLES(LATENCY_CYCLES)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .req_valid(req_valid),
    .req_rw(req_rw),
    .req_addr(req_addr),
    .req_wdata(req_wdata),
    .resp_ready(resp_ready),
    .resp_rdata(resp_rdata)
  );

  // 100 MHz clock, 10 ns period
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("mem_controller.vcd");
    $dumpvars(0, tb_mem_controller);
  end

  // Hold request stable long enough because DUT captures req_* in S_LATCH
  task automatic send_request(
    input logic        rw,
    input logic [31:0] addr,
    input logic [31:0] wdata
  );
    begin
      @(negedge clk);
      req_valid = 1'b1;
      req_rw    = rw;
      req_addr  = addr;
      req_wdata = wdata;

      // Hold through IDLE -> LATCH transition and LATCH capture
      repeat (2) @(negedge clk);

      req_valid = 1'b0;
      req_rw    = 1'b0;
      req_addr  = 32'h0;
      req_wdata = 32'h0;
    end
  endtask

  task automatic wait_done;
    begin
      wait (resp_ready === 1'b1);
      @(posedge clk);
      #1;
    end
  endtask

  task automatic write_word(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    begin
      $display("[%0t] WRITE addr=0x%08h data=0x%08h", $time, addr, data);
      send_request(1'b1, addr, data);
      wait_done();
    end
  endtask

  task automatic read_word_check(
    input logic [31:0] addr,
    input logic [31:0] expected
  );
    begin
      $display("[%0t] READ  addr=0x%08h expected=0x%08h", $time, addr, expected);
      send_request(1'b0, addr, 32'h0);
      wait_done();

      if (resp_rdata !== expected) begin
        error_count++;
        $error("[%0t] READ FAIL: addr=0x%08h expected=0x%08h got=0x%08h",
               $time, addr, expected, resp_rdata);
      end else begin
        $display("[%0t] READ PASS: addr=0x%08h data=0x%08h",
                 $time, addr, resp_rdata);
      end
    end
  endtask

  initial begin
    error_count = 0;
    req_valid = 1'b0;
    req_rw    = 1'b0;
    req_addr  = 32'h0;
    req_wdata = 32'h0;
    rst_n     = 1'b0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // Test 1: write/read word index 1, addr[4:2] = 1
    write_word(32'h0000_0004, 32'hA5A5_1234);
    read_word_check(32'h0000_0004, 32'hA5A5_1234);

    // Test 2: write/read word index 3, addr[4:2] = 3
    write_word(32'h0000_000C, 32'hDEAD_BEEF);
    read_word_check(32'h0000_000C, 32'hDEAD_BEEF);

    // Test 3: overwrite same address
    write_word(32'h0000_0004, 32'hCAFE_BABE);
    read_word_check(32'h0000_0004, 32'hCAFE_BABE);

    if (error_count != 0)
      $fatal(1, "[%0t] TEST FAILED: %0d error(s)", $time, error_count);

    $display("[%0t] ALL TESTS PASSED", $time);
    repeat (5) @(posedge clk);
    $finish;
  end

  initial begin
    #10_000;
    $fatal(1, "Simulation timeout");
  end

endmodule
