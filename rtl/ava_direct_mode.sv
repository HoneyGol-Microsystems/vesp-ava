import ava_pkg::*;

module ava_direct_mode (
    input  logic        clk,
    input  logic        reset,
    
    input  coords_t     coords,

    input  logic [31:0] palette_d,
    output logic [5:0]  palette_a,

    output logic [16:0]  vram_a,
    input  logic [31:0]  vram_d,

    output logic [23:0] pixel_out
);

    // This will hopefully be synthesized to use FPGA's built-in DSP blocks.
    // Memory has a latency of 1 => sending "next" address (+ 1).
    assign vram_a = coords.x + (coords.x * coords.y) + 1;

    // VRAM value is just an index to the palette RAM, which contains
    // resulting 24-bit color.
    assign palette_a = vram_d;
    assign pixel_out = palette_d;
    
endmodule