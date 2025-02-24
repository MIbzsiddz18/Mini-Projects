module Sap_tb;

  logic sap_clock;
  logic sap_reset;
  logic halt;

  SAP uut (
    .sap_clock(sap_clock),
    .sap_reset(sap_reset),
    .halt(halt)
  );
  
  
  initial begin
    sap_clock = 1'b0;
    forever #5 sap_clock = ~sap_clock;
  end

 
  initial begin
    sap_reset = 1;
    #10 sap_reset = 0;
    #10
    repeat (48) begin
      if(halt==1'b1)
        $finish;
      @(posedge sap_clock);
    end

    $finish;
  end
  
 
  initial begin
    $dumpfile("sap_wave.vcd");
    $dumpvars(0, Sap_tb);
  end

endmodule
