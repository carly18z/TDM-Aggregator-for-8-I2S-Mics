// =============================================================
// timing_gen.v
// Purpose : Generate mic-side I2S clocks only.
//           pi_sck is NOT generated here — it is clk_12m directly.
//
// Outputs:
//   mic_sck        — I2S bit clock to microphones (3 MHz)
//   mic_ws         — I2S word select (L/R)
//   mic_bclk_tick  — pulses one clk_12m cycle after falling edge of mic_sck
//   mic_bit_cnt    — current bit position within I2S word (0..31)
//   mic_word_done  — pulses when bit 31 is complete
//
// mic_sck frequency:
//   mic_sck = clk_12m / (2 * (MIC_DIV + 1))
//   MIC_DIV = 1 → 12MHz / 4 = 3 MHz
//
// mic_ws timing:
//   toggles ONE BCLK before MSB per I2S spec
//   (at mic_bit_cnt == MIC_WORD_BITS - 2)
// =============================================================

module i2s_mic_timing_gen (
    input  wire clk_12m,
    output reg        mic_sck       = 1'b0,
    output reg        mic_ws        = 1'b0,
    output reg        mic_bclk_tick = 1'b0,
    output reg [5:0]  mic_bit_cnt   = 6'd0,
    output reg        mic_word_done = 1'b0
);

    parameter integer MIC_DIV       = 1;
    parameter integer MIC_WORD_BITS = 32;

    // =========================================================
    // INTERNAL
    // =========================================================
    reg [15:0] mic_div_cnt  = 16'd0;
    reg        mic_sck_prev = 1'b0;

    // =========================================================
    // MIC SCK GENERATION
    // =========================================================
    always @(posedge clk_12m) begin
        mic_sck_prev <= mic_sck;
        if (mic_div_cnt == MIC_DIV) begin
            mic_div_cnt <= 0;
            mic_sck     <= ~mic_sck;
        end else begin
            mic_div_cnt <= mic_div_cnt + 1;
        end
    end

    // =========================================================
    // MIC BCLK TICK — fires on FALLING edge of mic_sck
    // I2S data is valid and stable on falling edge
    // =========================================================
    always @(posedge clk_12m) begin
        mic_bclk_tick <= (mic_sck_prev & ~mic_sck);
    end

    // =========================================================
    // MIC BIT COUNTER + mic_ws + mic_word_done
    //
    // I2S rule: mic_ws must change ONE BCLK before the MSB.
    // Toggle mic_ws at mic_bit_cnt == MIC_WORD_BITS-2 (one early).
    // Assert mic_word_done at mic_bit_cnt == MIC_WORD_BITS-1.
    // =========================================================
    always @(posedge clk_12m) begin
        mic_word_done <= 1'b0; // default pulse only

        if (mic_bclk_tick) begin
            if (mic_bit_cnt == MIC_WORD_BITS - 1)
                mic_bit_cnt <= 0;
            else
                mic_bit_cnt <= mic_bit_cnt + 1;

            if (mic_bit_cnt == MIC_WORD_BITS - 1)
                mic_word_done <= 1'b1;

            if (mic_bit_cnt == MIC_WORD_BITS - 2)
                mic_ws <= ~mic_ws;
        end
    end

endmodule
