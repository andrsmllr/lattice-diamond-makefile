`include "top.vh"

module OSCH (
   input    STDBY,
   output   OSC, SEDSTDBY ); //synthesis syn_black_box
   parameter NOM_FREQ = "66.5";
endmodule

module top #(
  parameter F_CLK = 24'd120000000, //! External reference clock frequency.
  parameter OC_OSC_FREQ = "66.5", //! On-chip oscillator frequency.
  parameter DEBUG_LEVEL = 0
) (
  input  wire       clk_i,
  input  wire       rst_i,
  input  wire [3:0] dip_sw_i,
  output wire [7:0] led_o
);

wire osc_clk;
OSCH #(
  .NOM_FREQ(OC_OSC_FREQ)
) on_board_rc_oscillator_inst (
  .STDBY(1'b0),
  .SEDSTDBY(),
  .OSC(osc_clk)
);

wire mclk = osc_clk;

localparam N_DIVCNTR = 16;
reg [23:00] divcntr [N_DIVCNTR-1:0];
reg [00:00] strb [N_DIVCNTR-1:0];

genvar i;
generate
for (i = 0; i < N_DIVCNTR; i = i + 1) begin
  always @ (posedge mclk)
  begin
    if (rst_i) begin
      divcntr[i] <= F_CLK;
      strb[i] <= 1'b0;
    end else begin
      divcntr[i] <= divcntr[i] - 1'd1;
      if (divcntr[i] == 0) begin
        divcntr[i] <= F_CLK/(i+1);
        strb[i] <= 1'b1;
      end else begin
        strb[i] <= 1'b0;
      end
    end
  end
end
endgenerate

wire led_strb = strb[dip_sw_i];

reg [7:0] led;
always @ (posedge mclk)
begin
  if (rst_i) begin
      led <= 'h0;
  end else begin
    if (led_strb == 1'b1) begin
      led <= led + 1'd1;
    end
  end
end

assign led_o = ~led;

endmodule
