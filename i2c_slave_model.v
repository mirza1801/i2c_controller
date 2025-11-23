`timescale 1ns / 1ps

module i2c_slave_model (
    inout wire sda,     // Bidirectional I2C data line
    input wire scl      // I2C clock line
);

    reg sda_dir = 0;     // 1 = drive SDA, 0 = release SDA (high impedance)
    reg sda_out = 1;     // Output value to drive on SDA

    assign sda = sda_dir ? sda_out : 1'bz;  // Tri-state SDA line based on direction

    reg [3:0] bit_cnt = 0;                  // Bit counter (counts up to 9)
    reg [7:0] response_data = 8'b10101010;  // Example data to send during read

    // Drive behavior on falling edge of SCL
    always @(negedge scl) begin
        if (bit_cnt == 8) begin
            // After 8 bits received, send ACK
            sda_dir <= 1;
            sda_out <= 0;
        end else if (bit_cnt < 8) begin
            // During read: drive one bit of response_data
            sda_dir <= 1;
            sda_out <= response_data[7 - bit_cnt];
        end else begin
            // Release SDA on other cycles
            sda_dir <= 0;
        end
    end

    // Count bits on rising edge of SCL
    always @(posedge scl) begin
        bit_cnt <= bit_cnt + 1;          // Increment bit counter
        if (bit_cnt == 9) begin
            bit_cnt <= 0;                // Reset after full byte + ACK/NACK
        end
    end

endmodule
