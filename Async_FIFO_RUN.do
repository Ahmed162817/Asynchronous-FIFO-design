vlib work
vlog Async_FIFO.v Async_FIFO_tb.sv +cover -covercells
vsim -voptargs=+acc work.Async_FIFO_tb -cover -sv_seed random
add wave *
add wave -position insertpoint  \
sim:/Async_FIFO_tb/Async_FIFO_instance/wr_ptr \
sim:/Async_FIFO_tb/Async_FIFO_instance/rd_ptr \
sim:/Async_FIFO_tb/Async_FIFO_instance/FIFO \
sim:/Async_FIFO_tb/OVERFLOW_cvr \
sim:/Async_FIFO_tb/UNDERFLOW_cvr
coverage save Async_FIFO_tb.ucdb -onexit -du work.Async_FIFO
run -all
#quit -sim
#vcover report Async_FIFO_tb.ucdb -details -annotate -all -output Code_Coverage_Report.txt