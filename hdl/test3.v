`include "test3.vh" 

module test3 #(
  parameter N = 32
) (
  input wire ck,
  input wire rst,
  input wire ce,
  input wire [N-1:0] da,
  input wire [N-1:0] db,
  output reg [N-1:0] qo
);

reg [N-1:0] da_reg;
reg [N-1:0] db_reg;

`ifdef TEST
always @ (posedge ck)
begin
  if (rst == 1'b1) begin
    da_reg <= 'd0;
    db_reg <= 'd0;
    qo <= 'd0;
  end else begin
    if (ce == 1'b1) begin
      da_reg <= da;
      db_reg <= db;
      qo <= da_reg + db_reg;
    end
  end
end
`endif

endmodule
