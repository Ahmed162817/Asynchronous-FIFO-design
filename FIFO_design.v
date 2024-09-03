module FIFO (data_in,wr_en,rd_en,clk_wr,clk_rd,rst,data_out,full,empty,overflow,underflow);

// parameter Declaration
parameter FIFO_WIDTH = 16;
parameter ADDR_SIZE = 9; 
parameter FIFO_DEPTH = 512 ;                   // There are 512 locations in the FIFO due to address = 9 bits (2^9 = 512)    

// inputs & outputs Declaration
input wr_en,rd_en,clk_wr,clk_rd,rst;          // There are two clocks one for reading & the other for writing
input [FIFO_WIDTH-1 : 0] data_in;
output reg [FIFO_WIDTH-1 : 0] data_out;
output reg overflow,underflow;              
output full,empty;

// FIFO memory declaration
reg [FIFO_WIDTH-1 : 0] FIFO [0 : FIFO_DEPTH-1];

// internal signals 
reg [ADDR_SIZE:0] wr_ptr , rd_ptr;                // we add extra bit to distinguish between the full & empty cases
reg [ADDR_SIZE:0] wr_ptr_sync0 , wr_ptr_sync1;   // write pointer after passing the 2FF synchronizer (0 --> output of first FF & 1 --> output of second FF)
reg [ADDR_SIZE:0] rd_ptr_sync0 , rd_ptr_sync1;  // read pointer after passing the 2FF synchronizer (0 --> output of first FF & 1 --> output of second FF)
reg [ADDR_SIZE:0] wr_ptr_gray , rd_ptr_gray;   //  these pointers are the gray coding version of read & write pointers 

// Always block for writing operation
always @(posedge clk_wr or posedge rst) begin
	if(rst)
		wr_ptr <= 0;
	else if(wr_en == 1 && full == 0) begin
		FIFO[ wr_ptr[ADDR_SIZE-1:0] ] <= data_in;
		wr_ptr <= wr_ptr + 1;
	end
end

// Always block for reading operation
always @(posedge clk_rd or posedge rst) begin
	if(rst) begin
		data_out <= 0;
		rd_ptr <= 0;
	end
	else if(rd_en == 1 && empty == 0) begin
		data_out <= FIFO[ rd_ptr[ADDR_SIZE-1:0] ];
		rd_ptr <= rd_ptr + 1;
	end
end

// Always block for converting binary coding read pointer into gray coding to avoid BUS synchronization issue
always @ (rd_ptr) begin
	rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;
end

// Always block for converting binary coding write pointer into gray coding to avoid BUS synchronization issue
always @ (wr_ptr) begin
	wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
end

// Synchronizer for the write pointer after passing read domain (Empty case)
always @(posedge clk_rd or posedge rst) begin
	if (rst) begin
		wr_ptr_sync0 <= 0;
		wr_ptr_sync1 <= 0;
	end
	else begin
		wr_ptr_sync0 <= wr_ptr_gray;
		wr_ptr_sync1 <= wr_ptr_sync0;
	end
end

// Synchronizer for the read pointer after passing write domain (Full case)
always @(posedge clk_wr or posedge rst) begin
	if (rst) begin
		rd_ptr_sync0 <= 0;
		rd_ptr_sync1 <= 0;
	end
	else begin
		rd_ptr_sync0 <= rd_ptr_gray;
		rd_ptr_sync1 <= rd_ptr_sync0;
	end
end

// Continous assignment for the combinational outputs (full & empty signals)
assign full = ( (wr_ptr_gray[ADDR_SIZE-2:0] == rd_ptr_sync1[ADDR_SIZE-2:0]) && (wr_ptr_gray[ADDR_SIZE-1] != rd_ptr_sync1[ADDR_SIZE-1]) && (wr_ptr_gray[ADDR_SIZE] != rd_ptr_sync1[ADDR_SIZE]) ) ? 1 : 0;
assign empty = ( wr_ptr_sync1 == rd_ptr_gray ) ? 1 : 0;

// Always block for the sequential output (overflow)
always @(posedge clk_wr or posedge rst) begin
	if(rst)
		overflow <= 0;
	else if (full == 1 && wr_en == 1)
		overflow <= 1;
	else 
		overflow <= 0;
end

// Always block for the sequential output (underflow)
always @(posedge clk_rd or posedge rst) begin
	if(rst)
		underflow <= 0;
	else if (empty == 1 && rd_en == 1)
		underflow <= 1;
	else 
		underflow <= 0;
end

endmodule