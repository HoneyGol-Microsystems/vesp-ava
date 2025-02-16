import ava_pkg::*;

module ava_controller (
    
    input   logic                           clk,
    input   logic                           reset,

    input   logic                           pixel_fifo_full,
    output  coords_t                        coords,
    output  logic    [VRAM_ADDR_WIDTH-1:0]  linear_coords,
    output  logic                           vblank
);

    always_ff @( posedge clk ) begin : coord_counter_proc
        if (reset) begin
            coords.x <= 'h0;
            coords.y <= 'h0;
        end else if (pixel_fifo_full) begin
            // Wait if fifo is full.
        end else if (coords.x == COORD_X_MAX) begin
            if (coords.y == COORD_Y_MAX) begin
                coords.x <= 'h0;                
                coords.y <= 'h0;
            end else begin                
                coords.x <= 'h0;
                coords.y <= coords.y + 1;
            end
        end else begin
            coords.x <= coords.x + 1;
        end
    end

    always_ff @( posedge clk ) begin : linear_coord_counter_proc
        if (reset) begin
            linear_coords <= 'h1; // Because the VRAM has a latency of 1, a headstart is needed.
        end else if (pixel_fifo_full) begin
            // Wait if fifo is full.
        end else if (linear_coords == (X_RES * Y_RES) - 1) begin
            linear_coords <= 'h0;
        end else begin
            linear_coords <= linear_coords + 1;
        end
    end
    
    assign vblank = coords.x == COORD_X_MAX && coords.y == COORD_Y_MAX;

endmodule