module vesp_ava_top (
    wishbone_p_if.slave wb,
    input   logic       hdmi_clk,
    input   logic       hdmi_clk_x5,
    input   logic       audio_clk,

    output  logic       pcm_empty_irq,
    output  logic       vblank_irq,

    // To HDMI port
    output  logic [2:0] tmds,
    output  logic       tmds_clock
);

    import ava_pkg::*;

    // Controller signals
    logic [LINEAR_COORDS_BITS-1:0] linear_coords;
    logic    vblank;
    logic    pcm_empty;

    // FIFO connections
    logic pixel_fifo_full;
    logic fifo_wr;
    logic [23:0] rendered_pixel;

    logic fifo_wr_rst_busy;
    logic fifo_rd_rst_busy;

    // VGA modules outputs
    vga_mode_t   vga_mode;
    logic [23:0] vga_text_pixel;
    logic [23:0] vga_direct_pixel;

    // VRAM connections
    logic [VRAM_ADDR_WIDTH-1:0] vram_a1;
    logic [31:0]                vram_do1;
    logic [31:0]                vram_di1;
    logic [3:0]                 vram_we1;
    logic                       vram_en1;

    logic [31:0]                vram_do2;
    logic [VRAM_ADDR_WIDTH-1:0] vram_a2;
    logic [VRAM_ADDR_WIDTH-1:0] vga_text_vram_addr;
    logic [VRAM_ADDR_WIDTH-1:0] vga_direct_vram_addr;

    // Palette RAM conections
    logic [PRAM_ADDR_WIDTH-1:0] pram_a1;
    logic [31:0]                pram_do1;
    logic [31:0]                pram_di1;
    logic [3:0]                 pram_we1;
    logic                       pram_en1;

    logic [PRAM_ADDR_WIDTH-1:0] pram_a2;
    logic [31:0]                pram_do2;

    // HDMI signals
    logic [9:0]                 hdmi_cx;
    logic [9:0]                 hdmi_cy;
    logic                       hdmi_in_frame;

    // =================================
    // System clock domain.
    // =================================
    always_comb begin : vram_addr_mux_proc
        unique case (vga_mode)
            VGA_TEXT_MODE:   vram_a2 = vga_text_vram_addr;
            VGA_DIRECT_MODE: vram_a2 = vga_direct_vram_addr; 
        endcase
    end

    ava_controller controller (
        .clk(wb.clk_i),
        .reset(wb.rst_i),

        .fifo_busy(pixel_fifo_full | fifo_wr_rst_busy),
        .coords(),
        .linear_coords(linear_coords),
        .vblank(vblank)
    );

    ava_wb wishbone_controller (
        .wb(wb),

        .vram_a(vram_a1),
        .vram_di(vram_di1),
        .vram_en(vram_en1),
        .vram_we(vram_we1),
        .vram_do(vram_do1),

        .pram_a(pram_a1),
        .pram_di(pram_di1),
        .pram_en(pram_en1),
        .pram_we(pram_we1),
        .pram_do(pram_do1),
        
        .vblank(vblank),
        .pcm_empty(pcm_empty),
        .vga_mode(vga_mode),
        .vblank_irq(vblank_irq),
        .pcm_empty_irq(pcm_empty_irq)
    );

    ava_sdpbram #(
        .WORD_COUNT(VRAM_WORD_COUNT),
        .WORD_WIDTH(32),
        .GRANULARITY(8)
    ) vram (
        .clk(wb.clk_i),
        
        .a1(vram_a1),
        .do1(vram_do1),
        .di1(vram_di1),
        .en1(vram_en1),
        .we1(vram_we1),
        
        .a2(vram_a2),
        .do2(vram_do2),
        // .en2(1'b1)
        .en2(~pixel_fifo_full)
    );

    ava_sdpdram #(
        .WORD_COUNT(PRAM_WORD_COUNT), // 256 24-bit colors (top 8 bit reserved)
        .WORD_WIDTH(32),
        .GRANULARITY(8)
    ) pram (
        .clk(wb.clk_i),
        
        .a1(pram_a1),
        .do1(pram_do1),
        .di1(pram_di1),
        .en1(pram_en1),
        .we1(pram_we1),

        .a2(pram_a2),
        .do2(pram_do2),
        .en2(1'b1)
    );

    ava_direct_mode direct_mode (
        .clk(wb.clk_i),
        .reset(wb.rst_i),
        .next_pixel(~pixel_fifo_full),

        .linear_coords(linear_coords),
        
        .palette_a(pram_a2),
        .palette_d(pram_do2),
        
        .vram_a(vga_direct_vram_addr),
        .vram_d(vram_do2),

        .pixel_out(vga_direct_pixel)
    );

    // =================================
    // HDMI clock domain.
    // =================================
    logic pixel_fifo_empty;
    logic fifo_rd;

    logic [23:0] hdmi_pixel;


    always_comb begin : pixel_mux_proc
        unique case (vga_mode)
            VGA_TEXT_MODE:   rendered_pixel = vga_text_pixel;
            VGA_DIRECT_MODE: rendered_pixel = vga_direct_pixel;
        endcase
    end

    // xpm_fifo_async: Asynchronous FIFO
    // Xilinx Parameterized Macro, version 2024.2
    xpm_fifo_async #(
        .CASCADE_HEIGHT(0),            // DECIMAL
        .CDC_SYNC_STAGES(2),           // DECIMAL
        .DOUT_RESET_VALUE("0"),        // String
        .ECC_MODE("no_ecc"),           // String
        // .EN_SIM_ASSERT_ERR("warning"), // String
        .FIFO_MEMORY_TYPE("auto"),     // String
        .FIFO_READ_LATENCY(0),         // DECIMAL
        .FIFO_WRITE_DEPTH(16),         // DECIMAL
        .FULL_RESET_VALUE(0),          // DECIMAL
        .RD_DATA_COUNT_WIDTH(1),       // DECIMAL
        .READ_DATA_WIDTH(24),          // DECIMAL
        .READ_MODE("fwft"),            // String
        .RELATED_CLOCKS(0),            // DECIMAL
        .SIM_ASSERT_CHK(1),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .USE_ADV_FEATURES("0000"),     // String
        .WAKEUP_TIME(0),               // DECIMAL
        .WRITE_DATA_WIDTH(24),         // DECIMAL
        .WR_DATA_COUNT_WIDTH(1)        // DECIMAL
    ) pixel_fifo (
    .almost_empty(),
    .almost_full(),
    .data_valid(),
    .dbiterr(),
    .dout(hdmi_pixel),
    .empty(pixel_fifo_empty),
    .full(pixel_fifo_full),
    .overflow(),
    .prog_empty(),
    .prog_full(),
    .rd_data_count(),
    .rd_rst_busy(fifo_rd_rst_busy),
    .sbiterr(),
    .underflow(),
    .wr_ack(),
    .wr_data_count(),
    .wr_rst_busy(fifo_wr_rst_busy),
    .din(rendered_pixel),
    .injectdbiterr(),
    .injectsbiterr(),
    .rd_clk(hdmi_clk),
    .rd_en(~pixel_fifo_empty & hdmi_in_frame & ~fifo_rd_rst_busy),
    .rst(wb.rst_i),
    .sleep(1'b0),
    .wr_clk(wb.clk_i),
    .wr_en(~pixel_fifo_full & ~fifo_wr_rst_busy)
    );
    // End of xpm_fifo_async_inst instantiation

    always_comb begin : in_frame_detect
        hdmi_in_frame = hdmi_cx <= COORD_X_MAX && hdmi_cy <= COORD_Y_MAX;
    end

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
        .reset(pixel_fifo_empty),
        .rgb(hdmi_pixel),
        .audio_sample_word(),
        .tmds(tmds),
        .tmds_clock(tmds_clock),
        .cx(hdmi_cx),
        .cy(hdmi_cy)
    );
endmodule