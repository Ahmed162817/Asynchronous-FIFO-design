module FIFO_tb;

// parameters Declaration
parameter FIFO_WIDTH = 16;
parameter ADDR_SIZE = 9;
parameter FIFO_DEPTH = 512;                 

// input & output Declaration
reg [FIFO_WIDTH-1:0] data_in;
reg wr_en, clk_wr, rd_en, clk_rd, rst;
wire [FIFO_WIDTH-1:0] data_out;
wire full,empty,overflow,underflow;

// Queue to push data_in
reg [FIFO_WIDTH-1:0] Queue[$];         // this is an associative array used to store input data & compare it with FIFO 
reg [FIFO_WIDTH-1:0] wdata;           // this register used to take the data stored in the first location in the Queue & compare it with the data_out read from the FIFO

// DUT instantiation
FIFO #(.FIFO_WIDTH(FIFO_WIDTH),.FIFO_DEPTH(FIFO_DEPTH),.ADDR_SIZE(ADDR_SIZE)) DUT (.*);

// Write clock generation
initial begin
	clk_wr = 0;
	forever
	#25 clk_wr = ~clk_wr;           // write clock period = 50ns	          
end

// Read clock generation
initial begin
	clk_rd = 0;
	forever
	#15 clk_rd = ~clk_rd;           // read clock period = 30ns	          
end

// Generate test stimulus & check the FIFO 
initial begin

$readmemh("initialized_FIFO.txt",DUT.FIFO);

//--------------Test reset operation-------//
rst = 1'b1;   wr_en = 1'b0;    rd_en = 0;   data_in = 0;       wdata = 0;
repeat(5) @(negedge clk_wr);

//-------------Test write operation----------//
rst = 1'b0;   wr_en = 1;
repeat(FIFO_DEPTH + 10) begin            // we write all the FIFO locations but add 10 more writes for overflow assertion
    data_in = $urandom;
    Queue.push_back(data_in);
    @(negedge clk_wr);
end
    
//----------Test Read operation-------------//
wr_en = 0;   rd_en = 1;
repeat(FIFO_DEPTH + 10) begin        // we read all the FIFO locations but add 10 more reads for underflow assertion
	if (!empty)                     // This condition help me not to take any additional values from the Queue if the FIFO is empty
    	wdata = Queue.pop_front();        
    @(negedge clk_rd);
    if(data_out !== wdata) 
        $error("At Time = %0t: The Comparison is Failed where expected wr_data = %h, data_out_FIFO = %h",$time, wdata, data_out);
    else 
        $display("At Time = %0t: The Comparison is Passed where expected wr_data = %h, data_out_FIFO = %h",$time, wdata, data_out);
end           
	$stop;
end         

endmodule