import ava_pkg::*;

module ava_direct_mode (
    input  logic                        clk,
    input  logic                        reset,
    
    input  logic [VRAM_ADDR_WIDTH-1:0]  linear_coords,

    input  logic [31:0]                 palette_d,
    output logic [PRAM_ADDR_WIDTH-1:0]  palette_a,

    output logic [VRAM_ADDR_WIDTH-1:0]  vram_a,
    input  logic [31:0]                 vram_d,

    output logic [23:0]                 pixel_out
);
    assign vram_a = linear_coords >> 2; // Each word contains 4 pixels.

    // VRAM value is just an index to the palette RAM, which contains
    // resulting 24-bit color.
    assign palette_a = vram_d[linear_coords[1:0]]; // Pixel is represented by a single byte in the word.
    assign pixel_out = palette_d;
    
endmodule