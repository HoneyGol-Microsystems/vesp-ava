import ava_pkg::*;

module ava_controller (
    
    input   logic       clk,
    input   logic       reset,

    input   logic       fifo_full,
    output  vga_mode_t  vga_mode,
    output  coords_t    coords,
    output  logic       vblank_irq
);

    always_ff @( posedge clk ) begin : coord_counter_proc
        if (reset) begin
            coords.x <= 'h0;
            coords.y <= 'h0;
        end else if (fifo_full) begin
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
    
    assign vga_mode   = VGA_DIRECT_MODE;
    assign vblank_irq = 1'b0;

endmodule