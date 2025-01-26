package ava_pkg;

    localparam COORD_X_MAX = 639;
    localparam COORD_Y_MAX = 479;

    typedef struct packed {
        logic [9:0] x;
        logic [8:0] y;
    } coords_t;

    typedef enum logic [0:0] { VGA_TEXT_MODE, VGA_DIRECT_MODE } vga_mode_t;

    // All memories have a word size of 32 bit.
    localparam VRAM_WORD_COUNT = 76800;
    localparam VRAM_ADDR_WIDTH = $clog2(VRAM_WORD_COUNT);
    localparam PRAM_WORD_COUNT = 64;
    localparam PRAM_ADDR_WIDTH = $clog2(PRAM_WORD_COUNT);

    typedef struct packed {
        logic [27:0] res;
        logic        pcm_empty_irq_en;
        logic        vblank_irq_en;
        logic        pcm_empty_irq_pending;
        logic        vblank_irq_pending;
    } ava_reg_interupts_t;

    typedef struct packer {
        logic       [30:0] reserved;
        vga_mode_t         mode;
    } ava_reg_video_setup_t;

endpackage