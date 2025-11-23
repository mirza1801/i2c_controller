TOP=i2c_master_tb
RTL=rtl/i2c_master.v
MODEL=models/i2c_slave_model.v
TB=tb/i2c_master_tb.v
LOGDIR=logs

all: run

run: $(RTL) $(MODEL) $(TB)
	@mkdir -p $(LOGDIR)
	vcs -sverilog -full64 -debug_access+all -timescale=1ns/1ps \
		$(RTL) $(MODEL) $(TB) -top $(TOP) -o simv
	./simv -l $(LOGDIR)/i2c.log -no_save

run-iverilog: $(RTL) $(MODEL) $(TB)
	iverilog -g2012 -o simv $(RTL) $(MODEL) $(TB)
	vvp simv

clean:
	rm -rf simv csrc *.daidir DVEfiles ucli.key *.vcd *.vpd xsim.dir *.log *.jou

.PHONY: all run run-iverilog clean
