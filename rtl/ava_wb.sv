import ava_pkg::*;

module ava_wb (
    wishbone_p_if.slave                 wb,

    output  logic [VRAM_ADDR_WIDTH-1:0] vram_a,
    output  logic [31:0]                vram_di,
    output  logic                       vram_en,
    output  logic [3:0]                 vram_we,
    input   logic [31:0]                vram_do,

    output  logic [PRAM_ADDR_WIDTH-1:0] pram_a,
    output  logic [31:0]                pram_di,
    output  logic                       pram_en,
    output  logic [3:0]                 pram_we,
    input   logic [31:0]                pram_do,

    input   logic                       vblank,
    input   logic                       pcm_empty,

    output  vga_mode_t                  vga_mode,
    output  logic                       vblank_irq,
    output  logic                       pcm_empty_irq
);
    localparam logic [1:0] ADR_REGSET = 2'b00;
    localparam logic [1:0] ADR_PRAM   = 2'b01;
    localparam logic [1:0] ADR_VRAM   = 2'b10;

    logic [0:0]  reg_latency_counter;
    logic [0:0]  pram_latency_counter;
    logic [0:0]  vram_latency_counter;
    logic        write;

    logic        reg_sel;
    logic        vram_sel;
    logic        pram_sel;

    logic [31:0] reg_out;
    logic [31:0] reg_offset;

    typedef struct packed {
        logic [31:0]          res_2;
        logic [31:0]          res_1;
        ava_reg_interupts_t   interrupts;
        ava_reg_video_setup_t video_setup;
    } regs_t;

    regs_t      regs;

    always_comb begin : wishbone_signal_handling
        // This is a simple pipelined peripheral; we can keep
        // with whatever master's pace is.
        wb.stall   = 1'b0;
    end

    always_comb begin : device_select
        reg_sel  = 1'b0;
        vram_sel = 1'b0;
        pram_sel = 1'b0;

        unique case (wb.adr[20:19])
            ADR_REGSET: reg_sel  = 1'b1;
            ADR_PRAM:   pram_sel = 1'b1;
            ADR_VRAM:   vram_sel = 1'b1;
        endcase
    end

    always_ff @( posedge wb.clk_i ) begin : operation_start
        if (wb.rst_i | ~wb.cyc) begin // Reset or unset cyc clears all pending operations.
            reg_latency_counter  <= 1'b0;
            pram_latency_counter <= 1'b0;
            vram_latency_counter <= 1'b0;
        end if (wb.cyc) begin       // Operations are valid iff cyc is set.
            write <= wb.we;     // Operation is selected at the beginning and stays the same -- only one reg suffices.
            // Strobe signalizes start of the operation.
            reg_latency_counter  <= (reg_latency_counter  << 1) | (wb.stb & reg_sel);
            pram_latency_counter <= (pram_latency_counter << 1) | (wb.stb & pram_sel);
            vram_latency_counter <= (vram_latency_counter << 1) | (wb.stb & vram_sel);
        end
    end

    always_comb begin : output_handling
        wb.dat_o = 'h0;
        wb.ack   = 1'b0;

        if (reg_latency_counter[$size(reg_latency_counter)-1]) begin
            wb.ack      = 1'b1;
            wb.dat_o    = reg_out;
        end else if (pram_latency_counter[$size(pram_latency_counter)-1]) begin
            wb.ack      = 1'b1; 
            wb.dat_o    = pram_do;     
        end else if (vram_latency_counter[$size(vram_latency_counter)-1]) begin
            wb.ack      = 1'b1;
            wb.dat_o    = vram_do;
        end
    end

    always_comb begin : memory_control
        vram_a  = wb.adr[31:2]; // Wishbone address is by bytes, whereas memory is addressed by words.
        vram_di = wb.dat_i;
        vram_en = vram_sel;
        vram_we = {4{vram_en}} & {4{write}} & wb.sel;

        pram_a  = wb.adr[31:2]; // Wishbone address is by bytes, whereas memory is addressed by words.
        pram_di = wb.dat_i;
        pram_en = pram_sel;
        pram_we = {4{pram_en}} & {4{write}} & wb.sel;
    end

    always_ff @( posedge wb.clk_i ) begin : register_addr_ff // Store address to simulate one clock cycle latency.
        reg_offset <= wb.adr[3:2];
    end

    always_comb begin : register_read_proc
        reg_out = regs[reg_offset * 32 +: 32];
    end 

    always_ff @(posedge wb.clk_i) begin : register_write_proc
        if (wb.rst_i) begin
            regs <= 'h0;
        end else if (wb.cyc && wb.stb && wb.we && reg_sel) begin
            if (reg_offset == 2'b01) begin
                regs[reg_offset * 32 +: 32] <= wb.dat_i | {pcm_empty & regs.interrupts.pcm_empty_irq_en, vblank & regs.interrupts.vblank_irq_en};
            end else begin
                regs[reg_offset * 32 +: 32] <= wb.dat_i;
            end
        end else begin
            regs.interrupts <= regs.interrupts | {pcm_empty & regs.interrupts.pcm_empty_irq_en, vblank & regs.interrupts.vblank_irq_en};
        end
    end

    assign vblank_irq    = regs.interrupts.vblank_irq_pending;
    assign pcm_empty_irq = regs.interrupts.pcm_empty_irq_pending;
    assign vga_mode      = regs.video_setup.mode;
endmodule