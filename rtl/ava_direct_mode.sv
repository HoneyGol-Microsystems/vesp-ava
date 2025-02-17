import ava_pkg::*;

module ava_direct_mode (
    input  logic                            clk,
    input  logic                            reset,
    input  logic                            next_pixel,

    input  logic [LINEAR_COORDS_BITS-1:0]   linear_coords,

    input  logic [31:0]                     palette_d,
    output logic [PRAM_ADDR_WIDTH-1:0]      palette_a,

    output logic [VRAM_ADDR_WIDTH-1:0]      vram_a,
    input  logic [31:0]                     vram_d,

    output logic [23:0]                     pixel_out
);
    logic [1:0] pixel_offset;

    // Because there is a one-cycle latency in VRAM (BRAM implementation), we need to store a part
    // of the coords that is used to index in the loaded word.
    always_ff @( posedge clk ) begin : pixel_offset_ff_proc
        if (reset) begin
            pixel_offset <= 2'b0;
        end else if (next_pixel) begin
            pixel_offset <= linear_coords[1:0];
        end
    end

    assign vram_a = linear_coords >> 2; // Each word contains 4 pixels.

    // VRAM value is just an index to the palette RAM, which contains
    // resulting 24-bit color.
    assign palette_a = vram_d[pixel_offset * 8 +: 8]; // Pixel is represented by a single byte in the word.
    assign pixel_out = palette_d;
    
endmodule