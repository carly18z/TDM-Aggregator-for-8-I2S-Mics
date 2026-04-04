// =============================================================
// frame_packer.v
// Purpose : On a single SOF-style pulse, copy four 64-bit lane
//           frames into one 256-bit Pi-side frame register.
//
// Frame layout (MSB first):
//   [255:192] lane0_frame = {ch0, ch1}
//   [191:128] lane1_frame = {ch2, ch3}
//   [127: 64] lane2_frame = {ch4, ch5}
//   [ 63:  0] lane3_frame = {ch6, ch7}
// =============================================================

module superframe_loader #(
    parameter integer WORD_BITS = 32
)(
    input  wire clk_12m,
    input  wire superframe_ready,
    input  wire [2*WORD_BITS-1:0] lane0_frame,
    input  wire [2*WORD_BITS-1:0] lane1_frame,
    input  wire [2*WORD_BITS-1:0] lane2_frame,
    input  wire [2*WORD_BITS-1:0] lane3_frame,

    output reg [8*WORD_BITS-1:0] frame_reg   = {(8*WORD_BITS){1'b0}},
    output reg                   frame_valid = 1'b0
);

always @(posedge clk_12m) begin
    frame_valid <= 1'b0;

    if (superframe_ready) begin
        frame_reg   <= {lane0_frame, lane1_frame, lane2_frame, lane3_frame};
        frame_valid <= 1'b1;
    end
end

endmodule
