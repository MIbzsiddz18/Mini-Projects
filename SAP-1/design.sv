///////////////////////////////////PC ////////////////////////////////////////////////////////////
module program_counter (
  input logic clock,
  input logic reset,        // Add reset signal
  input logic count_enable,
  input logic output_enable,
  output logic [15:0] instruction
);

  reg [10:0] count; // 11 bit address counter

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      count <= 16'd0;       // Initialize count to 0 on reset
    end else if (count_enable) begin
      count <= (count + 1) % 8;
    end
  end

  always_comb begin
    instruction = output_enable ? {5'b00000,count}: 16'bz; // Tri-state logic
  end

endmodule



///////////////////////////////////////// MAR /////////////////////////////////////
module memory_address_register(
  input logic clock,
  input logic reset,
  input logic load_enable,
  input logic [15:0] address_in,
  output logic [10:0] address_out
);
  
  logic [10:0] address; // 11 bit MAR

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      address <= 16'b0; 
    end else if (load_enable) begin
      address <= address_in;
    end
  end
  

 assign address_out = address; 
endmodule

//////////////////////////////////  RAM /////////////////////////////////////////////////////


module ram(
  input logic [10:0] address,         // 11-bit address 
    input logic [15:0] data_in,       // 16-bit data input
    input logic output_enable,        // Output enable signal
    input logic load_enable,          // Load enable signal
    output logic [15:0] data_out      // 16-bit data output
);

    // 30x16 RAM: 16 locations, each 16 bits
  logic [30:0] memory [15:0];    // 16 slots, 16 bits each

    // Writing data into memory
  always @(*) begin
        if (load_enable) begin
          memory[address] <= data_in;
        end
    end

    // Initialize the RAM with arbitrary values
    initial begin
        // Instruction memory (First 8 slots)
        
      memory[0] <= 16'b0000000000001000; // Load the value  to Accumalator
      memory[1] <= 16'b0011100000001001; // Add the value  to Accumalator
      memory[2] <= 16'b0011000000001010; // Subtract the value  from Accumalator
      memory[3] <= 16'b0101100000000000; // Left shift the value in Accumalator
      memory[4] <= 16'b1001100000000111; // Store the value in Accumalator  to ram
      memory[5] <= 16'b0111000000000000; //reset B register
      memory[6] <= 16'b1001000000000000;//Halt 
      memory[7] <= 16'b0000000000000000;

      // Data memory (Next 8 slots)
      memory[8]  <= 16'b0000000000001010; // 
      memory[9]  <= 16'b0000000000000010; // 
      memory[10] <= 16'b0000000000000100; // 
      memory[11] <= 16'b0000000000000000;
      memory[12] <= 16'b0000000000000000;
      memory[13] <= 16'b0000000000000000;
      memory[14] <= 16'b0000000000000000;
      memory[15] <= 16'b0000000000000000;
    end
  
  	always@(output_enable) begin
      data_out <= output_enable ? memory[address] : 16'bzzzzzzzzzzzzzzzz;
	end

endmodule


/////////////////////////////////////////////////IR ///////////////////////////////////
module instruction_register(
    input logic clock,
  	input logic reset,
    input logic load_enable,
    input logic output_enable,
    input logic [15:0] instruction,
  	output logic [4:0] opcode_out,
  	output logic [15:0] address_out
);

    // Internal register to store the instruction
  reg [4:0] opcode; //5  bit opcode
  reg [10:0] address; //addresss

  	always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            opcode <= 5'b0;
            address <= 4'b0;
        end else begin
            if (load_enable) begin
              opcode <= instruction[15:11]; 
              address <= instruction[10:0]; 
            end
        end
    end  

  	assign opcode_out = opcode;
  
  	always@(output_enable) begin
      address_out = output_enable ? {5'b00000,address} : 16'bzzzz_zzzz_zzzz_zzzz;
  	end

endmodule


///////////////////////////////////////////Accumulator /////////////////////////////
module accumulator(
    input logic clock,
    input logic reset,                    // Reset signal added
    input logic load_enable,
    input logic output_enable,
    input logic [4:0] operation,
    input logic [15:0] data_in,
    output logic [15:0] data_out,     // Accumulator operation output
    output logic [15:0] data          // Direct connection to ALU
);

    reg [15:0] acc; 

    // Sequential Block for Accumulator Operations
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            acc <= 16'b0;           // Reset accumulator to 0
        end else if (load_enable) begin
            acc <= data_in;         // Load new data into the accumulator
        end
    end

    always @(*) begin
        case (operation)
            5'b01000: acc = ~acc; // NOT operation
            5'b01001: acc = 16'b0; // RESET operation
            5'b01010: acc = acc + 1; // INCREMENT operation
            5'b01011: acc = acc << 1; // LEFT SHIFT operation
            5'b01100: acc = acc >> 1; // RIGHT SHIFT operation
            default: acc = acc; // Default case, retain current value
        endcase
    end
  
    assign data = acc;

     always@(output_enable) begin
       data_out = output_enable ? acc : 16'bzzzz_zzzz_zzzz_zzzz; 
    end

endmodule


///////////////////////////////////  ALU ///////////////////////////////////
module alu( 
    input [4:0] operation,
    input logic [15:0] accumulator_data_in,
    input logic [15:0] b_register_data_in,
    input logic output_enable,
    output logic [15:0] result
);

    logic [15:0] computed_result; // Internal signal for result calculation

    // Combinational logic for ALU operations
    always @(*) begin
        case (operation)
            5'b00001: computed_result = accumulator_data_in + b_register_data_in; // Add
            5'b00010: computed_result = accumulator_data_in - b_register_data_in; // Subtract
            5'b00011: computed_result = accumulator_data_in * b_register_data_in; // Multiply

            5'b00100: begin // Division
                if (b_register_data_in != 0)
                    computed_result = accumulator_data_in / b_register_data_in; 
                else
                    computed_result = 16'b0; 
            end
            5'b00101: computed_result = accumulator_data_in ^ b_register_data_in; // XOR
            5'b00110: computed_result = accumulator_data_in | b_register_data_in; // OR
            5'b00111: computed_result = accumulator_data_in & b_register_data_in; // AND
            default: computed_result = 16'b0; 
        endcase
    end

    always @(output_enable) begin
     	result = output_enable ? computed_result : 16'bzzzz_zzzz_zzzz;
  	end

endmodule


////////////////////////////////////// B register ////////////////////////


module b_register(
    input logic clock,
  	input logic reset,
    input logic load_enable,
    input logic [4:0] operation,
    input logic [15:0] data_in,
  	output logic [15:0] data	// Direct connection to ALU
);
    reg [15:0] b_reg; // B register

    // Sequential Block for Accumulator Operations
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            b_reg <= 16'b0;           // Reset B registor
        end else if (load_enable) begin
            b_reg <= data_in;         // Load data
        end
    end

     always @(*) begin
        case (operation)
            5'b01110: b_reg = 16'b0; 		// RESET operation
            5'b01111: b_reg = b_reg + 1;	// INCREMENT operation
            5'b10000: b_reg = b_reg << 1; 	// LEFT SHIFT operation
            5'b10001: b_reg = b_reg >> 1; 	// RIGHT SHIFT operation
            default: b_reg = b_reg; // Default case, retain current value
        endcase
    end
  
  assign data = b_reg; // Continous connection to ALU
 
endmodule


/////////////////////////////////  CU /////////////////////////////////


module control_unit #(parameter 
    T1 = 4'b0001, T2 = 4'b0010, T3 = 4'b0011, 
    T4 = 4'b0100, T5 = 4'b0101, T6 = 4'b0110,
    T7 = 4'b0111, T8 = 4'b1000, T9 = 4'b1001,
    T10 = 4'b1010, T11 = 4'b1011, T12 = 4'b1100
    )
    ( 
        input logic clear,
        input logic clock,
      	input logic [4:0] opcode,
        output logic clear_out,
        output logic clock_out,
      	output logic [10:0] control_signals,
        output logic halt
    );

    logic [3:0] state; // Current state
    logic [3:0] next_state; // Next state
  
    // Current state
    always_ff @(negedge clock or posedge clear) begin
      if (clear)
        state <= T1;
      else
        state <= next_state;
    end

    always_comb
    begin
        case(state)
            T1: next_state = T2;
            T2: begin
                    case (opcode)
                        // Load A
                        5'b00000: next_state = T3; 
                      
                        // Add, Subtract, Multiply, Divide, XOR, OR, AND
                        5'b00001, 5'b00010, 5'b00011, 
                        5'b00100, 5'b00101, 5'b00110, 
                        5'b00111: next_state = T5; 

                        // Not A, Reset A, Increment A, Decrement A, Left Shift A, Right Shift A
                        5'b01000, 5'b01001, 5'b01010, 
                        5'b01011, 5'b01100, 5'b01101: next_state = T8; 

                        // Reset B, Increment B, Left Shift B, Right Shift B
                        5'b01110, 5'b01111, 5'b10000, 
                        5'b10001: next_state = T9;

                        // Halt
                        5'b10010: next_state = T12; 
                        
                        // Store A
                        5'b10011: next_state = T10; 

                        default: next_state = T1; 
                    endcase
                end

            // Load
            T3: next_state = T4;

            // Add, Subtract, Multiply, Divide, XOR, OR, AND
            T5: next_state = T6; 
            T6: next_state = T7;//storing in B then result to A

            // store back in Ram
            T10: next_state = T11; 

            default: next_state = T1;
        endcase
    end

    always_comb
        begin
            case (state)
                T1:  control_signals = 11'b10100000000; // PC OE, MAR LE
                T2:  control_signals = 11'b01001100000; // PC CE, RAM OE, IR LE
                T3:  control_signals = 11'b00100010000; // IR OE, MAR LE
                T4:  control_signals = 11'b00001001000; // RAM OE, Accumalator LE
                T5:  control_signals = 11'b00100010000; // IR OE, MAR LE
                T6:  control_signals = 11'b00001000001; // RAM OE, B Register LE
                T7:  control_signals = 11'b00000001010; // Accumalator LE, ALU OE
                T8:  control_signals = 11'b00000000000; // All control signals off, Internal operations in Accumalator
                T9:  control_signals = 11'b00000000000; // All control signals off, Internal operations in B Register
                T10: control_signals = 11'b00100010000; // IR OE, MAR LE
                T11: control_signals = 11'b00010000100; // RAM LE, Accumalator OE
              
                T12: halt = 1'b1; // Halt
            endcase
        end

        assign clear_out = clear; 
        assign clock_out = clock;
endmodule

////////////////////////////////////output register ////////////////////////////////////////////////////
module OutputRegister(
    input CLK,                // Clock signal
    input [15:0] DataIn,      // 16-bit input from the bus
    input Load,               // Load signal (1 to load, 0 to hold)
    output reg [15:0] DataOut // 16-bit output to the binary display
);

    always @(posedge CLK) begin
        if (Load) begin
            // Load the input data into the register on the clock edge
            DataOut <= DataIn;
            $display("OutputRegister: Load triggered, DataOut loaded with %b", DataIn);
        end
    end

endmodule


////////////////////////////////Main processing module /////////////////////////////////////////////////


module SAP(
    input logic sap_clock,
    input logic sap_reset,
    output logic halt,
    output logic result
);

  wire [15:0] data_bus;
  logic [10:0] control_signals;
  logic [15:0] accumulator_out;
  logic [15:0] b_register_out;
  logic [4:0] opcode;
  logic [10:0] address; // 11 bit address
  logic clock;
  logic reset;
  

    // Instantiate all the components

    control_unit CU(
        .clock(sap_clock),
        .clear(sap_reset),
        .opcode(opcode),                    // Opcode from IR
        .clock_out(clock),                
   		.clear_out(reset),             
   		.control_signals(control_signals),  // Control signals to control bus
        .halt(halt)                         // Output control signal to control bus
    );

    ram RAM(
        .address(address),                  // Address from IR
        .data_in(data_bus),                 // Data bus to RAM
      	.output_enable(control_signals[6]), // Output enable from control unit
      	.load_enable(control_signals[7]),   // Load enable from control unit
        .data_out(data_bus)                 // Data bus from RAM
    );

    accumulator ACC(
        .clock(clock),                      // Clock from control unit
      	.reset(reset),						// Reset signal
      	.load_enable(control_signals[3]),   // Load enable from control unit
      	.output_enable(control_signals[2]), // Output enable from control unit
        .operation(opcode),                 // Operation from IR
        .data_in(data_bus),                 // Data bus to accumulator
        .data_out(data_bus),                // Data bus from accumulator
        .data(accumulator_out)              // Data output to ALU
    );

    b_register BREG(
        .clock(clock),                      // Clock from control unit
      	.reset(reset),						// Reset signal
        .operation(opcode),                 // Operation from IR
        .load_enable(control_signals[0]),  // Load enable from control unit
        .data_in(data_bus),                 // Data bus to B register
        .data(b_register_out)               // Data output to ALU
    );

    instruction_register IR (
        .clock(clock),                      // Clock from control unit
      	.reset(reset),						// Reset signal
      	.load_enable(control_signals[5]),   // Load enable from control unit
      	.output_enable(control_signals[4]), // Output enable from control unit
        .instruction(data_bus),             // Data bus to IR
        .opcode_out(opcode),                // Opcode output to control unit
       	.address_out(data_bus)              // Address output to bus
    );

    memory_address_register MAR(
        .clock(clock),                      // Clock from control unit
      	.reset(reset),						// Reset signal	
      	.load_enable(control_signals[8]),   // Load enable from control unit
        .address_in(data_bus),              // Data bus to MAR
        .address_out(address)               // Address output to RAM
    );

    program_counter PC(
        .clock(clock),                      // Clock from control unit
      	.reset(reset),						// Reset Signal
      	.count_enable(control_signals[9]),  // Count enable from control unit
      	.output_enable(control_signals[10]), // Output enable from control unit
        .instruction(data_bus)              // Data bus to PC
    );

    alu ALU(
        .operation(opcode),                 // Operation from IR
        .accumulator_data_in(accumulator_out), // Data from accumulator
        .b_register_data_in(b_register_out), // Data from B register
      	.output_enable(control_signals[1]), // Output enable from control unit
        .result(data_bus)                   // Result output to data bus
    );
    
  
endmodule



