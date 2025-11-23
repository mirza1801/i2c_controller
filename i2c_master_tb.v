`timescale 1ns / 1ps

module i2c_master_tb;

    reg clk = 0;                      // Simulation clock
    reg rst = 1;                      // Active-high synchronous reset
    reg start = 0;                    // Signal to start I2C transaction
    reg rw = 0;                       // Read/Write control: 0 = write, 1 = read
    reg [6:0] addr = 7'h42;           // I2C slave address
    reg [7:0] data_in = 8'b11000000;  // Data to write during write transaction
    wire [7:0] data_out;              // Data read from slave
    wire scl, sda, busy, ack_received, done;  // I2C and control signals

    always #5 clk = ~clk;             // Clock generation: 100 MHz (10 ns period)

    // Instantiate I2C master
    i2c_master master (
        .clk(clk), .rst(rst), .start(start), .rw(rw),
        .addr(addr), .data_in(data_in), .data_out(data_out),
        .scl(scl), .sda(sda), .busy(busy),
        .ack_received(ack_received), .done(done)
    );

    // Instantiate I2C slave model
    i2c_slave_model slave (
        .sda(sda),
        .scl(scl)
    );

    initial begin
        $dumpfile("dump.vcd");              // Create VCD file for waveform dump
        $dumpvars(0, i2c_master_tb);        // Dump all variables in testbench

        #20 rst = 0;                         // Deassert reset after 20 ns
        #100;                               // Wait for system to stabilize

        // WRITE transaction
        $display("Starting WRITE");
        start = 1; rw = 0;                  // Start signal with write mode
        #10 start = 0;                      // Pulse start low
        wait(done);                         // Wait until transaction is done
        $display("Write Done. ACK = %b", ack_received);

        #500;                               // Wait some time before next transaction

        // READ transaction
        $display("Starting READ");
        start = 1; rw = 1;                  // Start signal with read mode
        #10 start = 0;
        wait(done);
        $display("Read Done. ACK = %b, Data = %b", ack_received, data_out);

        #500 $finish;                       // End simulation
    end

endmodule
