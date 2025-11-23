`timescale 1ns / 1ps

module i2c_master (
    input wire clk, rst,                      // Clock and reset
    input wire start,                         // Start signal for transaction
    input wire rw,                            // Read/Write control: 0 = write, 1 = read
    input wire [6:0] addr,                    // 7-bit slave address
    input wire [7:0] data_in,                 // Data to be sent (in write mode)
    output reg [7:0] data_out,                // Data received (in read mode)
    output reg scl,                           // I2C clock line
    inout wire sda,                           // I2C data line (bidirectional)
    output reg busy,                          // High when transaction is in progress
    output reg ack_received,                  // Acknowledgment status from slave
    output reg done                           // High when transaction is complete
);

    parameter CLK_DIV = 250;                  // Clock divider for SCL generation
    parameter BIT_LIMIT = 3;                  // Only 4-bit transactions used for speed demo

    reg [15:0] clk_cnt;                       // Clock divider counter
    reg scl_en;                               // Enable SCL toggling
    reg [2:0] state;                          // FSM state variable
    reg [2:0] bit_cnt;                        // Bit counter (counts down)
    reg [7:0] shift;                          // Shift register for TX/RX data
    reg data_phase = 0;                       // Flag: 0 = address, 1 = data phase

    reg sda_out = 1;                          // SDA output value
    reg sda_dir = 1;                          // SDA direction: 1 = drive, 0 = release
    assign sda = sda_dir ? sda_out : 1'bz;    // Tristate SDA assignment
    wire sda_in = sda;                        // SDA input from bus

    // FSM states
    parameter IDLE = 0, START = 1, SEND = 2, ACK = 3, READ = 4, STOP = 5, DONE = 6;

    // SCL generation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            scl <= 1;
        end else if (scl_en) begin
            if (clk_cnt == CLK_DIV-1) begin   // Toggle SCL when divider reached
                clk_cnt <= 0;
                scl <= ~scl;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end else begin
            scl <= 1;                         // Keep SCL high when not enabled
            clk_cnt <= 0;
        end
    end

    // Main FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            ack_received <= 0;
            data_out <= 0;
            sda_out <= 1;
            sda_dir <= 1;
            scl_en <= 0;
            data_phase <= 0;
        end else begin
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin          // Wait for start signal
                        busy <= 1;
                        scl_en <= 1;          // Enable SCL
                        state <= START;
                    end
                end

                START: begin
                    if (scl && clk_cnt == 0) begin // Start condition on SCL high
                        sda_out <= 0;         // Pull SDA low
                        sda_dir <= 1;
                        shift <= {addr, rw};  // Load address + R/W bit
                        bit_cnt <= BIT_LIMIT; // Load bit counter
                        state <= SEND;
                        data_phase <= 0;      // Address phase
                    end
                end

                SEND: begin
                    if (!scl && clk_cnt == 0) begin // Send data on falling edge
                        sda_out <= shift[bit_cnt];  // Send bit
                        if (bit_cnt == 0) begin
                            sda_dir <= 0;     // Release SDA for ACK
                            state <= ACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end

                ACK: begin
                    if (scl && clk_cnt == 0) begin  // Sample ACK on SCL high
                        ack_received <= ~sda_in;    // ACK is 0, NACK is 1
                        sda_dir <= 1;       // Take back control of SDA
                        sda_out <= 0;

                        if (!data_phase && !rw) begin // Next: data phase (write)
                            shift <= data_in;
                            bit_cnt <= BIT_LIMIT;
                            state <= SEND;
                            data_phase <= 1;
                        end else if (rw && !data_phase) begin // Next: data phase (read)
                            bit_cnt <= BIT_LIMIT;
                            state <= READ;
                            data_phase <= 1;
                            sda_dir <= 0;   // Release SDA to allow slave to drive
                        end else begin
                            state <= STOP;  // Go to stop condition
                        end
                    end
                end

                READ: begin
                    if (scl && clk_cnt == 0) begin  // Sample data on SCL high
                        data_out[bit_cnt] <= sda_in;
                        if (bit_cnt == 0) begin
                            state <= STOP;
                            sda_dir <= 1;
                            sda_out <= 1; // NACK to end read
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end

                STOP: begin
                    if (!scl && clk_cnt == 0) begin // Begin stop on falling edge
                        sda_out <= 0;
                        sda_dir <= 1;
                    end
                    if (scl && clk_cnt == 0) begin  // Complete stop on rising edge
                        sda_out <= 1;
                        scl_en <= 0;               // Disable SCL
                        state <= DONE;
                    end
                end

                DONE: begin
                    busy <= 0;
                    done <= 1;
                    state <= IDLE;                 // Return to idle
                end
            endcase
        end
    end

endmodule
