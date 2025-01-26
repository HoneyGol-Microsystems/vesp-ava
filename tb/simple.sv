module simple_tb ();
    
    logic           clk;
    logic           reset;

    wishbone_p_if   wb(
        .clk_i(clk),
        .rst_i(reset)
    );
    logic           hdmi_clk;
    logic           hdmi_clk_x5;

    vesp_ava_top dut(
        .wb(wb),

        .hdmi_clk(hdmi_clk),
        .hdmi_clk_x5(hdmi_clk_x5),

        .audio_clk(),
        .tmds(),
        .tmds_clock()
    );

    initial begin
        `ifdef QUESTA
            $wlfdumpvars();
        `else
            $dumpvars;
        `endif

        for (logic [8:0] i = 0; i < 256; i++) begin
            dut.pram.mem[i] = {4{i[7:0]}};
        end

        for (int i = 0; i < 76800; i++) begin
            dut.vram.mem[i] = i % 256;
        end

        reset = 1'b1;
        repeat (5) begin
            @(posedge clk);
        end
        reset = 1'b0;

        #1us;
        $finish;
    end

    // 100 MHz clock.
    always begin
        clk <= 1'b0;
        #5ns;
        clk <= 1'b1;
        #5ns;
    end

    // 25.2 MHz HDMI clock.
    always begin
        hdmi_clk <= 1'b0;
        #20ns;
        hdmi_clk <= 1'b1;
        #20ns;
    end

    // 25.2 * 5 HDMI clock.
    always begin
        hdmi_clk_x5 <= 1'b0;
        #4ns;
        hdmi_clk_x5 <= 1'b1;
        #4ns;
    end

endmodule