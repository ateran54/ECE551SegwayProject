// Generate a 4-bit up/down counter with enable and reset. 
// When en is high, on the rising edge of the clk if up_dwn_n is high cnt should be incremented,  
// when up_dwn_n is low cnt should be decremented. When en is low cnt should hold its value. 
// When rst_n is low cnt should be reset to 0.
module counter (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic up_dwn_n,
    output logic [3:0] cnt
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'b0000; // Reset counter to 0
        end else if (en) begin
            if (up_dwn_n) begin
                cnt <= cnt + 1; // Increment counter
            end else begin
                cnt <= cnt - 1; // Decrement counter
            end
        end
        // If en is low, hold the current value of cnt
    end
endmodule // I added this comment so the code would compile, otherwise this worked first try.
