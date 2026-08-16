module mem_controller #(
    parameter int ADDR_W          = 5,   // for DEPTH_WORDS=8, index uses [4:2] = 3 bits
    parameter int DEPTH_WORDS     = 8,   // downscaled from 64
    parameter int LATENCY_CYCLES  = 3
) (
    input  logic              clk,
    input  logic              rst_n,

    input  logic              req_valid,
    input  logic              req_rw,      // 0=read, 1=write
    input  logic [31:0]       req_addr,
    input  logic [31:0]       req_wdata,

    output logic              resp_ready,  // 1-cycle pulse when done
    output logic [31:0]       resp_rdata
);

    // internal memory (smaller)
    logic [31:0] mem [0:DEPTH_WORDS-1];

    // FSM
    typedef enum logic [1:0] { S_IDLE, S_LATCH, S_WAIT, S_RESPOND } state_t;
    state_t state_q, state_d;

    // latched request
    logic        lat_rw_q,    lat_rw_d;
    logic [31:0] lat_addr_q,  lat_addr_d;
    logic [31:0] lat_wdata_q, lat_wdata_d;

    // wait counter
    logic [$clog2(LATENCY_CYCLES+1)-1:0] wait_q, wait_d;

    // computed index
    logic [$clog2(DEPTH_WORDS)-1:0] idx;

    // registered response data
    logic [31:0] resp_rdata_q;

    // word index from latched address (word aligned)
    always_comb begin
        idx = lat_addr_q[ADDR_W-1:2];
    end

    assign resp_rdata = resp_rdata_q;

    // next-state logic + resp_ready pulse
    always_comb begin
        resp_ready = 1'b0;

        state_d      = state_q;
        lat_rw_d     = lat_rw_q;
        lat_addr_d   = lat_addr_q;
        lat_wdata_d  = lat_wdata_q;
        wait_d       = wait_q;

        case (state_q)
            S_IDLE: begin
                wait_d = '0;
                if (req_valid)
                    state_d = S_LATCH;
            end

            S_LATCH: begin
                lat_rw_d    = req_rw;
                lat_addr_d  = req_addr;
                lat_wdata_d = req_wdata;

                if (LATENCY_CYCLES > 0) begin
                    wait_d  = LATENCY_CYCLES[$bits(wait_d)-1:0];
                    state_d = S_WAIT;
                end else begin
                    wait_d  = '0;
                    state_d = S_RESPOND;
                end
            end

            S_WAIT: begin
                if (wait_q != 0)
                    wait_d = wait_q - 1;
                if (wait_q == 1)
                    state_d = S_RESPOND;
            end

            S_RESPOND: begin
                resp_ready = 1'b1;
                state_d    = S_IDLE;
            end

            default: state_d = S_IDLE;
        endcase
    end

    // sequential logic (including memory read/write)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= S_IDLE;
            lat_rw_q     <= 1'b0;
            lat_addr_q   <= 32'h0;
            lat_wdata_q  <= 32'h0;
            wait_q       <= '0;
            resp_rdata_q <= 32'h0;
            // NOTE: memory NOT cleared on reset to reduce logic
        end else begin
            state_q     <= state_d;
            lat_rw_q    <= lat_rw_d;
            lat_addr_q  <= lat_addr_d;
            lat_wdata_q <= lat_wdata_d;
            wait_q      <= wait_d;

            if (state_q == S_RESPOND) begin
                if (lat_rw_q) begin
                    // WRITE
                    if (idx < DEPTH_WORDS)
                        mem[idx] <= lat_wdata_q;
                    resp_rdata_q <= 32'h0;
                end else begin
                    // READ
                    if (idx < DEPTH_WORDS)
                        resp_rdata_q <= mem[idx];
                    else
                        resp_rdata_q <= 32'hDEAD_BEEF;
                end
            end
        end
    end

endmodule
