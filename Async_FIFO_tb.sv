class RandomInputs #(parameter FIFO_WIDTH = 4);

randc bit [FIFO_WIDTH-1:0] data_in;

constraint Input_data
{
	data_in dist {[0:(2**FIFO_WIDTH)-1] :/ 100};
}
endclass

module Async_FIFO_tb();

// Parameters Declaration
parameter FIFO_WIDTH = 4;						
parameter FIFO_DEPTH = 8;                               

// Inputs & Outputs Declaration
logic clk_wr,clk_rd,rst_n;          		
logic wr_en,rd_en;							
logic [FIFO_WIDTH-1:0] data_in;
logic [FIFO_WIDTH-1:0] data_out;             
logic full,empty;
logic overflow,underflow;

// Queue to push data_in
logic [FIFO_WIDTH-1:0] Queue [$];        // This is an associative array used to store input data & compare it with FIFO 
logic [FIFO_WIDTH-1:0] wdata;           // This register used to take the data stored in the first location in the Queue & compare it with the data_out read from the FIFO
int pass_count,fail_count;

// DUT instantiation
Async_FIFO #(.FIFO_WIDTH(FIFO_WIDTH),.FIFO_DEPTH(FIFO_DEPTH)) Async_FIFO_instance (.*);

// Initial block for Write clock generation (Fast clock)
initial begin
	clk_wr = 0;
	forever
	#5 clk_wr = ~clk_wr;           // Write clock period = 10 ns 	          
end

// Initial block for Read clock generation (Slow clock)	
initial begin
	clk_rd = 0;
	forever
	#7 clk_rd = ~clk_rd;           // Read clock period = 14 ns           
end

// Create an object from the class
RandomInputs #(.FIFO_WIDTH(FIFO_WIDTH)) obj1 = new();

// Initial block for Generating test stimulus & check the FIFO 
initial begin

	$readmemb("Initialized_FIFO.txt",Async_FIFO_instance.FIFO);

	//--------------Test reset operation-------//
	rst_n = 1'b0;   wr_en = 1'b0;    rd_en = 0;   data_in = 0;       wdata = 0;
	repeat(2) @(negedge clk_wr);			  // Wait 2 clock cycle to check the system reset
	rst_n = 1'b1;

	//-------------Test write operation----------//
	repeat(FIFO_DEPTH + 2) begin            // we write all the FIFO locations but add 2 more writes for overflow assertion
		assert(obj1.randomize());
		data_in = obj1.data_in;
		fifo_write(data_in);
	end

	// Wait 1 clock cycle before reading
    @(negedge clk_rd);
		
	//----------Test Read operation-------------//
	wr_en = 0;   rd_en = 1;
	repeat(FIFO_DEPTH + 2) begin        // we read all the FIFO locations but add 2 more reads for underflow assertion
		fifo_read();
	end

	// Display final values of Counters  
	$display("\n===========================================================================");   
	$display("At the end of the Simulation ---> Pass counter = %0d , Fail counter = %0d",pass_count,fail_count); 
	$display("===========================================================================\n");      
	$stop;
end         

// Task 1 : Write data_in to FIFO
task fifo_write(input [FIFO_WIDTH-1:0] din);
	if (!full) begin
		data_in = din;
		wr_en = 1;
		@(negedge clk_wr);
		Queue.push_back(din);
	end
	else begin				// Attempt write to trigger overflow signal
		data_in = din;
		wr_en = 1;
		@(negedge clk_wr);
	end
	wr_en = 0;
endtask

// Task 2 : Read data_out from FIFO
task fifo_read();
	if (!empty) begin			
		rd_en = 1;
		@(negedge clk_rd);
		if (data_out !== Queue.pop_front()) begin
			$display("Mismatch at time %0t : Expected data = %0h , Actual Read data from FIFO = %0h", $time, Queue.pop_front(), data_out);
			fail_count++;
		end
		else begin
			pass_count++;
		end
	end
	else begin				// Attempt read to trigger underflow
		rd_en = 1;
		@(negedge clk_rd);
	end
	rd_en = 0;
endtask

// Check the overflow signal for proper operation
property OVERFLOW;
    @(posedge clk_wr) disable iff (!rst_n) (full && wr_en) |=> (overflow == 1);         
endproperty
OVERFLOW_chk : assert property (OVERFLOW) else $fatal("At time = %0t --> There is a Bug in the overflow logic !!",$time);
OVERFLOW_cvr : cover property (OVERFLOW);

// Check the underflow signal for proper operation
property UNDERFLOW;
    @(posedge clk_rd) disable iff (!rst_n) (empty && rd_en) |=> (underflow == 1);         
endproperty
UNDERFLOW_chk : assert property (UNDERFLOW) else $fatal("At time = %0t --> There is a Bug in the underflow logic !!",$time);
UNDERFLOW_cvr : cover property (UNDERFLOW);

endmodule