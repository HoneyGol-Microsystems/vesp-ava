module vesp_ava_top (
    wishbone_p_if.slave wb,
    input   logic       hdmi_clk,
    input   logic       hdmi_clk_x5,
    input   logic       audio_clk,

    // To HDMI port
    output  logic [2:0] tmds,
    output  logic       tmds_clock
);

    import ava_pkg::*;

    // =================================
    // System clock domain.
    // =================================
    // Controller signals
    coords_t coords;
    logic    vblank_irq;

    // FIFO connections
    logic fifo_full;
    logic fifo_wr;
    logic [23:0] rendered_pixel;

    // VGA modules outputs
    vga_mode_t   vga_mode;
    logic [23:0] vga_text_pixel;
    logic [23:0] vga_direct_pixel;

    // VRAM connections
    logic [31:0]                vram_a1;
    logic [31:0]                vram_do1;
    logic [31:0]                vram_di1;
    logic [3:0]                 vram_we1;
    logic                       vram_en1;

    logic [31:0]                vram_do2;
    logic                       vram_en2;
    logic [VRAM_ADDR_WIDTH-1:0] vram_a2;
    logic [VRAM_ADDR_WIDTH-1:0] vga_text_vram_addr;
    logic [VRAM_ADDR_WIDTH-1:0] vga_direct_vram_addr;

    // Palette RAM conections
    logic [PRAM_ADDR_WIDTH-1:0] pram_a2;
    logic [31:0]                pram_do2;

    always_comb begin : vram_addr_mux_proc
        unique case (vga_mode)
            VGA_TEXT_MODE:   vram_a2 = vga_text_vram_addr;
            VGA_DIRECT_MODE: vram_a2 = vga_direct_vram_addr; 
        endcase
    end

    ava_controller controller (
        .clk(wb.clk_i),
        .reset(wb.rst_i),

        .fifo_full(fifo_full),
        .vga_mode(vga_mode),
        .coords(coords),
        .vblank_irq(vblank_irq)
    );

    ava_wb wishbone_controller (
        .clk(wb.clk_i),
        .reset(wb.rst_i),
        
        .vram_a(vram_a1),
        .vram_di(vram_di1),
    );

    ava_sdpbram #(
        .WORD_COUNT(76800),
        .WORD_WIDTH(32),
        .GRANULARITY(8)
    ) vram (
        .clk(wb.clk_i),
        
        .a1(),
        .do1(),
        .di1(),
        .en1(),
        .we1(),
        
        .a2(vram_a2),
        .do2(vram_do2),
        .en2(~fifo_full)
    );

    ava_sdpdram #(
        .WORD_COUNT(256), // 256 24-bit colors (top 8 bit reserved)
        .WORD_WIDTH(32),
        .GRANULARITY(8)
    ) pram (
        .clk(wb.clk_i),
        
        .a1(),
        .do1(),
        .di1(),
        .en1(),
        .we1(),

        .a2(pram_a2),
        .do2(pram_do2),
        .en2(1'b1)
    );

    ava_direct_mode direct_mode (
        .clk(),
        .reset(),

        .coords(coords),
        
        .palette_a(pram_a2),
        .palette_d(pram_do2),
        
        .vram_a(vga_direct_vram_addr),
        .vram_d(vram_do2),

        .pixel_out(vga_direct_pixel)
    );

    // =================================
    // HDMI clock domain.
    // =================================
    logic fifo_empty;
    logic fifo_rd;

    logic [23:0] hdmi_pixel;


    always_comb begin : pixel_mux_proc
        unique case (vga_mode)
            VGA_TEXT_MODE:   rendered_pixel = vga_text_pixel;
            VGA_DIRECT_MODE: rendered_pixel = vga_direct_pixel;
        endcase        
    end


    async_fifo #(
        .DSIZE(24),
        .ASIZE(2),
        .FALLTHROUGH("TRUE")
    ) pixel_fifo(
        .wclk(wb.clk_i),
        .wrst_n(~wb.rst_i),
        .winc(~fifo_full),
        .wdata(rendered_pixel),
        .wfull(fifo_full),
        .awfull(), // Almost full. Not used.

        .rclk(hdmi_clk),
        .rrst_n(~wb.rst_i), // Not used.
        .rinc(1'b1),
        .rdata(hdmi_pixel),
        .rempty(fifo_empty),
        .arempty() // Almost empty. Not used.
    );

    hdmi #(
        .VIDEO_ID_CODE(1),                // 640x480@60
        .IT_CONTENT(1'b1),                // Do not filter
        .DVI_OUTPUT(1'b0),                // Use full-fledged HDMI
        .VIDEO_REFRESH_RATE(60),
        .AUDIO_RATE(44100),
        .AUDIO_BIT_WIDTH(16),
        .VENDOR_NAME({"HGM",40'b0}),
        .PRODUCT_DESCRIPTION({"VESP Megatron", 24'b0}),
        .SOURCE_DEVICE_INFORMATION(8'h09) // Present as "PC General"
    ) hdmi_transmitter (
        .clk_pixel(hdmi_clk),
        .clk_pixel_x5(hdmi_clk_x5),
        .clk_audio(audio_clk),
        .reset(fifo_empty),
        .rgb(hdmi_pixel),
        .audio_sample_word(),
        .tmds(tmds),
        .tmds_clock(tdms_clock)
    );
endmodule