module Top_Module(
    input CLK100MHZ,
    input btnC,
    output cs,
    output sdin,
    output sclk,
    output d_cn,
    output resn,
    output vccen,
    output pmoden
);

// Clock divider: 100 MHz / 16 = 6.25 MHz
reg [3:0] clk_div = 0;
always @(posedge CLK100MHZ) begin
    clk_div <= clk_div + 1;
end
wire clk_6_25MHz = clk_div[3];

// OLED interface wires
wire frame_begin, sending_pixels, sample_pixel;
wire [12:0] pixel_index;
reg [15:0] pixel_data;

// Instantiate the OLED display module
Oled_Display oled(
    .clk(clk_6_25MHz),
    .reset(btnC),
    .frame_begin(frame_begin),
    .sending_pixels(sending_pixels),
    .sample_pixel(sample_pixel),
    .pixel_index(pixel_index),
    .pixel_data(pixel_data),
    .cs(cs),
    .sdin(sdin),
    .sclk(sclk),
    .d_cn(d_cn),
    .resn(resn),
    .vccen(vccen),
    .pmoden(pmoden),
    .teststate()
);

// Pixel data generation for "NAMAN JAIN"
always @* begin
    // Calculate row and column from pixel_index (96 columns, 64 rows)
    integer row = pixel_index / 96;
    integer column = pixel_index % 96;
    
    // Text area: 10 chars * 8 pixels = 80 pixels wide, centered at column 8 to 87, rows 28 to 35
    if (row >= 28 && row <= 35 && column >= 8 && column <= 87) begin
        integer char_index = (column - 8) / 8;         // Which character (0 to 9)
        integer local_column = (column - 8) % 8;       // Column within character (0 to 7)
        integer local_row = row - 28;                  // Row within character (0 to 7)
        reg [7:0] bitmap_row;
        
        case (char_index)
            0: begin // "N"
                case (local_row)
                    0: bitmap_row = 8'b11000011;
                    1: bitmap_row = 8'b11000111;
                    2: bitmap_row = 8'b11001111;
                    3: bitmap_row = 8'b11011111;
                    4: bitmap_row = 8'b11101111;
                    5: bitmap_row = 8'b11100111;
                    6: bitmap_row = 8'b11100011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            1: begin // "A"
                case (local_row)
                    0: bitmap_row = 8'b00011000;
                    1: bitmap_row = 8'b00111100;
                    2: bitmap_row = 8'b01100110;
                    3: bitmap_row = 8'b11000011;
                    4: bitmap_row = 8'b11111111;
                    5: bitmap_row = 8'b11000011;
                    6: bitmap_row = 8'b11000011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            2: begin // "M"
                case (local_row)
                    0: bitmap_row = 8'b11000011;
                    1: bitmap_row = 8'b11100111;
                    2: bitmap_row = 8'b11111111;
                    3: bitmap_row = 8'b11011011;
                    4: bitmap_row = 8'b11000011;
                    5: bitmap_row = 8'b11000011;
                    6: bitmap_row = 8'b11000011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            3: begin // "A"
                case (local_row)
                    0: bitmap_row = 8'b00011000;
                    1: bitmap_row = 8'b00111100;
                    2: bitmap_row = 8'b01100110;
                    3: bitmap_row = 8'b11000011;
                    4: bitmap_row = 8'b11111111;
                    5: bitmap_row = 8'b11000011;
                    6: bitmap_row = 8'b11000011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            4: begin // "N"
                case (local_row)
                    0: bitmap_row = 8'b11000011;
                    1: bitmap_row = 8'b11000111;
                    2: bitmap_row = 8'b11001111;
                    3: bitmap_row = 8'b11011111;
                    4: bitmap_row = 8'b11101111;
                    5: bitmap_row = 8'b11100111;
                    6: bitmap_row = 8'b11100011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            5: begin // " "
                bitmap_row = 8'b00000000;
            end
            6: begin // "J"
                case (local_row)
                    0: bitmap_row = 8'b00001111;
                    1: bitmap_row = 8'b00000111;
                    2: bitmap_row = 8'b00000111;
                    3: bitmap_row = 8'b00000111;
                    4: bitmap_row = 8'b11000111;
                    5: bitmap_row = 8'b11100111;
                    6: bitmap_row = 8'b01111110;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            7: begin // "A"
                case (local_row)
                    0: bitmap_row = 8'b00011000;
                    1: bitmap_row = 8'b00111100;
                    2: bitmap_row = 8'b01100110;
                    3: bitmap_row = 8'b11000011;
                    4: bitmap_row = 8'b11111111;
                    5: bitmap_row = 8'b11000011;
                    6: bitmap_row = 8'b11000011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            8: begin // "I"
                case (local_row)
                    0: bitmap_row = 8'b00111100;
                    1: bitmap_row = 8'b00111100;
                    2: bitmap_row = 8'b00011000;
                    3: bitmap_row = 8'b00011000;
                    4: bitmap_row = 8'b00011000;
                    5: bitmap_row = 8'b00011000;
                    6: bitmap_row = 8'b00111100;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            9: begin // "N"
                case (local_row)
                    0: bitmap_row = 8'b11000011;
                    1: bitmap_row = 8'b11000111;
                    2: bitmap_row = 8'b11001111;
                    3: bitmap_row = 8'b11011111;
                    4: bitmap_row = 8'b11101111;
                    5: bitmap_row = 8'b11100111;
                    6: bitmap_row = 8'b11100011;
                    7: bitmap_row = 8'b00000000;
                endcase
            end
            default: bitmap_row = 8'b00000000;
        endcase
        
        // Set pixel to white (0xFFFF) if bitmap bit is 1, else black (0x0000)
        if (bitmap_row[7 - local_column]) begin
            pixel_data = 16'hFFFF;
        end else begin
            pixel_data = 16'h0000;
        end
    end else begin
        pixel_data = 16'h0000; // Background is black
    end
end

endmodule