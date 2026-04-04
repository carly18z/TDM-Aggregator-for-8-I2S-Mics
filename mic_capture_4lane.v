// =============================================================
// mic_capture_4lane.v
// Purpose : Capture four I2S lanes into four 64-bit stereo lane
//           registers and present a superframe pulse when the
//           right word of each lane completes.
//
// Lane → channel mapping:
//   mic_sd1: ch0 (L), ch1 (R)
//   mic_sd2: ch2 (L), ch3 (R)
//   mic_sd3: ch4 (L), ch5 (R)
//   mic_sd4: ch6 (L), ch7 (R)
//
// The architecture follows the desired synchronous gearbox model:
// each lane accumulates a 64-bit stereo frame, then one SOF-style
// pulse (`superframe_ready`) indicates that all four lanes can be
// copied into the 256-bit Pi-side shift register in parallel.
// =============================================================

module tdm_lane_capture #(
    parameter integer WORD_BITS = 32
)(
    input  wire clk_12m,
    input  wire mic_bclk_tick,
    input  wire mic_word_done,
    input  wire mic_ws,

    input  wire mic_sd1,
    input  wire mic_sd2,
    input  wire mic_sd3,
    input  wire mic_sd4,

    output reg [WORD_BITS-1:0] ch0 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch1 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch2 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch3 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch4 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch5 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch6 = {WORD_BITS{1'b0}},
    output reg [WORD_BITS-1:0] ch7 = {WORD_BITS{1'b0}},

    output reg [2*WORD_BITS-1:0] lane0_frame = {(2*WORD_BITS){1'b0}},
    output reg [2*WORD_BITS-1:0] lane1_frame = {(2*WORD_BITS){1'b0}},
    output reg [2*WORD_BITS-1:0] lane2_frame = {(2*WORD_BITS){1'b0}},
    output reg [2*WORD_BITS-1:0] lane3_frame = {(2*WORD_BITS){1'b0}},
    output reg                   superframe_ready = 1'b0
);

reg [WORD_BITS-1:0] lane0_shift = {WORD_BITS{1'b0}};
reg [WORD_BITS-1:0] lane1_shift = {WORD_BITS{1'b0}};
reg [WORD_BITS-1:0] lane2_shift = {WORD_BITS{1'b0}};
reg [WORD_BITS-1:0] lane3_shift = {WORD_BITS{1'b0}};

reg word_slot_ws = 1'b0;
reg word_started = 1'b0;

wire [WORD_BITS-1:0] lane0_word = {lane0_shift[WORD_BITS-2:0], mic_sd1};
wire [WORD_BITS-1:0] lane1_word = {lane1_shift[WORD_BITS-2:0], mic_sd2};
wire [WORD_BITS-1:0] lane2_word = {lane2_shift[WORD_BITS-2:0], mic_sd3};
wire [WORD_BITS-1:0] lane3_word = {lane3_shift[WORD_BITS-2:0], mic_sd4};

always @(posedge clk_12m) begin
    if (mic_bclk_tick) begin
        lane0_shift <= lane0_word;
        lane1_shift <= lane1_word;
        lane2_shift <= lane2_word;
        lane3_shift <= lane3_word;
    end
end

always @(posedge clk_12m) begin
    if (mic_word_done) begin
        word_started <= 1'b0;
    end else if (mic_bclk_tick && !word_started) begin
        word_slot_ws <= mic_ws;
        word_started <= 1'b1;
    end
end

always @(posedge clk_12m) begin
    superframe_ready <= 1'b0;

    if (mic_word_done) begin
        if (word_slot_ws == 1'b0) begin
            ch0 <= lane0_word;
            ch2 <= lane1_word;
            ch4 <= lane2_word;
            ch6 <= lane3_word;

            lane0_frame[2*WORD_BITS-1:WORD_BITS] <= lane0_word;
            lane1_frame[2*WORD_BITS-1:WORD_BITS] <= lane1_word;
            lane2_frame[2*WORD_BITS-1:WORD_BITS] <= lane2_word;
            lane3_frame[2*WORD_BITS-1:WORD_BITS] <= lane3_word;
        end else begin
            ch1 <= lane0_word;
            ch3 <= lane1_word;
            ch5 <= lane2_word;
            ch7 <= lane3_word;

            lane0_frame[WORD_BITS-1:0] <= lane0_word;
            lane1_frame[WORD_BITS-1:0] <= lane1_word;
            lane2_frame[WORD_BITS-1:0] <= lane2_word;
            lane3_frame[WORD_BITS-1:0] <= lane3_word;

            superframe_ready <= 1'b1;
        end
    end
end

endmodule
