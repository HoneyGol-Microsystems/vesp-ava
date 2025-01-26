import ava_pkg::*;

module ava_controller (
    
    input   logic       clk,
    input   logic       reset,

    input   logic       pixel_fifo_full,
    output  coords_t    coords,
    output  logic       vblank
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
    
    assign vblank = coords.x == COORD_X_MAX && coords.y == COORD_Y_MAX;

endmodule