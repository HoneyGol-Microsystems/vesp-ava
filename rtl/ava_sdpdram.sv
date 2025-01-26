// Simple dual-port distributed RAM (second port is read-only)..
module ava_sdpdram #(
    parameter  WORD_COUNT,
    parameter  WORD_WIDTH,
    parameter  GRANULARITY,

    localparam GRAN_CNT   = WORD_WIDTH / GRANULARITY,
    localparam ADDR_WIDTH = $clog2(WORD_COUNT)
) (
    input  logic                   clk,

    input  logic [ADDR_WIDTH-1:0]  a1,
    input  logic [WORD_WIDTH-1:0]  di1,
    input  logic                   en1,
    input  logic [GRAN_CNT-1:0]    we1,
    output logic [WORD_WIDTH-1:0]  do1,

    input  logic [ADDR_WIDTH-1:0]  a2,
    input  logic                   en2,
    output logic [WORD_WIDTH-1:0]  do2
);

    (* ram_style = "distributed" *) logic [WORD_WIDTH-1:0] mem [WORD_COUNT];

    always_ff @( posedge clk ) begin : port1_proc
        for (int i = 0; i < GRAN_CNT; i++) begin
            if (we1[i]) begin
                mem[a1][(i * GRANULARITY) +: GRANULARITY] <= di1[(i * GRANULARITY) +: GRANULARITY];
            end
        end
    end

    assign do1 = (en1) ? mem[a1] : 'h0;
    assign do2 = (en2) ? mem[a2] : 'h0;

endmodule