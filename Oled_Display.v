module Oled_Display(
    input clk, reset,
    output frame_begin, sending_pixels, sample_pixel,
    output [11:0] pixel_index, // 128*32 = 4096, needs 12 bits
    input [15:0] pixel_data,
    output cs, sdin, sclk, d_cn, resn, vccen, pmoden,
    output [4:0] teststate
);

localparam Width = 128;
localparam Height = 32;
localparam PixelCount = Width * Height; // 4096
localparam PixelCountWidth = 12; // ceil(log2(4096))

parameter ClkFreq = 6250000; // 6.25 MHz
localparam FrameFreq = 60;
localparam FrameDiv = ClkFreq / FrameFreq; // 104166
localparam FrameDivWidth = 17; // ceil(log2(104166))

reg [16:0] frame_counter;
assign frame_begin = frame_counter == 0;

// State Machine
localparam PowerDelay = 20; // ms
localparam ResetDelay = 3; // us
localparam VccEnDelay = 20; // ms
localparam StartupCompleteDelay = 100; // ms
localparam MaxDelay = StartupCompleteDelay;
localparam MaxDelayCount = (ClkFreq * MaxDelay) / 1000; // 625000
reg [19:0] delay;

localparam StateCount = 32;
localparam StateWidth = 5;

localparam PowerUp = 5'b00000;
localparam Reset = 5'b00001;
localparam ReleaseReset = 5'b00011;
localparam EnableDriver = 5'b00010;
localparam DisplayOff = 5'b00110;
localparam SetRemapDisplayFormat = 5'b00111;
localparam SetStartLine = 5'b00101;
localparam SetOffset = 5'b00100;
localparam SetNormalDisplay = 5'b01100;
localparam SetMultiplexRatio = 5'b01101;
localparam SetMasterConfiguration = 5'b01111;
localparam DisablePowerSave = 5'b01110;
localparam SetPhaseAdjust = 5'b01010;
localparam SetDisplayClock = 5'b01011;
localparam SetSecondPrechargeA = 5'b01001;
localparam SetSecondPrechargeB = 5'b01000;
localparam SetSecondPrechargeC = 5'b11000;
localparam SetPrechargeLevel = 5'b11001;
localparam SetVCOMH = 5'b11011;
localparam SetMasterCurrent = 5'b11010;
localparam SetContrastA = 5'b11110;
localparam SetContrastB = 5'b11111;
localparam SetContrastC = 5'b11101;
localparam DisableScrolling = 5'b11100;
localparam ClearScreen = 5'b10100;
localparam VccEn = 5'b10101;
localparam DisplayOn = 5'b10111;
localparam PrepareNextFrame = 5'b10110;
localparam SetColAddress = 5'b10010;
localparam SetRowAddress = 5'b10011;
localparam WaitNextFrame = 5'b10001;
localparam SendPixel = 5'b10000;

assign sending_pixels = state == SendPixel;
assign resn = state != Reset;
assign d_cn = sending_pixels;
assign vccen = state == VccEn || state == DisplayOn ||
    state == PrepareNextFrame || state == SetColAddress ||
    state == SetRowAddress || state == WaitNextFrame || state == SendPixel;
assign pmoden = !reset;

reg [4:0] state;
wire [4:0] next_state = fsm_next_state(state, frame_begin, pixel_index);

function [4:0] fsm_next_state;
    input [4:0] state;
    input frame_begin;
    input [11:0] pixels_remain;
    case (state)
        PowerUp: fsm_next_state = Reset;
        Reset: fsm_next_state = ReleaseReset;
        ReleaseReset: fsm_next_state = EnableDriver;
        EnableDriver: fsm_next_state = DisplayOff;
        DisplayOff: fsm_next_state = SetRemapDisplayFormat;
        SetRemapDisplayFormat: fsm_next_state = SetStartLine;
        SetStartLine: fsm_next_state = SetOffset;
        SetOffset: fsm_next_state = SetNormalDisplay;
        SetNormalDisplay: fsm_next_state = SetMultiplexRatio;
        SetMultiplexRatio: fsm_next_state = SetMasterConfiguration;
        SetMasterConfiguration: fsm_next_state = DisablePowerSave;
        DisablePowerSave: fsm_next_state = SetPhaseAdjust;
        SetPhaseAdjust: fsm_next_state = SetDisplayClock;
        SetDisplayClock: fsm_next_state = SetSecondPrechargeA;
        SetSecondPrechargeA: fsm_next_state = SetSecondPrechargeB;
        SetSecondPrechargeB: fsm_next_state = SetSecondPrechargeC;
        SetSecondPrechargeC: fsm_next_state = SetPrechargeLevel;
        SetPrechargeLevel: fsm_next_state = SetVCOMH;
        SetVCOMH: fsm_next_state = SetMasterCurrent;
        SetMasterCurrent: fsm_next_state = SetContrastA;
        SetContrastA: fsm_next_state = SetContrastB;
        SetContrastB: fsm_next_state = SetContrastC;
        SetContrastC: fsm_next_state = DisableScrolling;
        DisableScrolling: fsm_next_state = ClearScreen;
        ClearScreen: fsm_next_state = VccEn;
        VccEn: fsm_next_state = DisplayOn;
        DisplayOn: fsm_next_state = PrepareNextFrame;
        PrepareNextFrame: fsm_next_state = SetColAddress;
        SetColAddress: fsm_next_state = SetRowAddress;
        SetRowAddress: fsm_next_state = WaitNextFrame;
        WaitNextFrame: fsm_next_state = frame_begin ? SendPixel : WaitNextFrame;
        SendPixel: fsm_next_state = (pixel_index == PixelCount-1) ? PrepareNextFrame : SendPixel;
        default: fsm_next_state = PowerUp;
    endcase
endfunction

assign teststate = state;

// SPI Master
localparam SpiCommandMaxWidth = 40;
localparam SpiCommandBitCountWidth = 6;

reg [5:0] spi_word_bit_count;
reg [SpiCommandMaxWidth-1:0] spi_word;

wire spi_busy = spi_word_bit_count != 0;
assign cs = !spi_busy;
assign sclk = clk | !spi_busy;
assign sdin = spi_word[SpiCommandMaxWidth-1] & spi_busy;

// Video
assign sample_pixel = (state == WaitNextFrame && frame_begin) ||
    (sending_pixels && frame_counter[3:0] == 0);
assign pixel_index = sending_pixels ? frame_counter[16:4] : 0;

always @(negedge clk) begin
    if (reset) begin
        frame_counter <= 0;
        delay <= 0;
        state <= 0;
        spi_word <= 0;
        spi_word_bit_count <= 0;
    end else begin
        frame_counter <= (frame_counter == FrameDiv-1) ? 0 : frame_counter + 1;

        if (spi_word_bit_count > 1) begin
            spi_word_bit_count <= spi_word_bit_count - 1;
            spi_word <= {spi_word[SpiCommandMaxWidth-2:0], 1'b0};
        end else if (delay != 0) begin
            spi_word <= 0;
            spi_word_bit_count <= 0;
            delay <= delay - 1;
        end else begin
            state <= next_state;
            case (next_state)
                PowerUp: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= (ClkFreq * PowerDelay) / 1000;
                end
                Reset: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= (ClkFreq * ResetDelay) / 1000;
                end
                ReleaseReset: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= (ClkFreq * ResetDelay) / 1000;
                end
                EnableDriver: begin
                    spi_word <= {16'hFD12, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                DisplayOff: begin
                    spi_word <= {8'hAE, {SpiCommandMaxWidth-8{1'b0}}};
                    spi_word_bit_count <= 8;
                    delay <= 1;
                end
                SetRemapDisplayFormat: begin
                    spi_word <= {16'hA072, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetStartLine: begin
                    spi_word <= {16'hA100, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetOffset: begin
                    spi_word <= {16'hA200, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetNormalDisplay: begin
                    spi_word <= {8'hA4, {SpiCommandMaxWidth-8{1'b0}}};
                    spi_word_bit_count <= 8;
                    delay <= 1;
                end
                SetMultiplexRatio: begin
                    spi_word <= {16'hA81F, {SpiCommandMaxWidth-16{1'b0}}}; // 32 rows
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetMasterConfiguration: begin
                    spi_word <= {16'hAD8E, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                DisablePowerSave: begin
                    spi_word <= {16'hB00B, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetPhaseAdjust: begin
                    spi_word <= {16'hB131, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetDisplayClock: begin
                    spi_word <= {16'hB3F0, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetSecondPrechargeA: begin
                    spi_word <= {16'h8A64, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetSecondPrechargeB: begin
                    spi_word <= {16'h8B78, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetSecondPrechargeC: begin
                    spi_word <= {16'h8C64, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetPrechargeLevel: begin
                    spi_word <= {16'hBB3A, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetVCOMH: begin
                    spi_word <= {16'hBE3E, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetMasterCurrent: begin
                    spi_word <= {16'h8706, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetContrastA: begin
                    spi_word <= {16'h8191, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetContrastB: begin
                    spi_word <= {16'h8250, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                SetContrastC: begin
                    spi_word <= {16'h837D, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 1;
                end
                DisableScrolling: begin
                    spi_word <= {8'h2E, {SpiCommandMaxWidth-8{1'b0}}}; // SSD1306 command
                    spi_word_bit_count <= 8;
                    delay <= 1;
                end
                ClearScreen: begin
                    spi_word <= {40'h2500007F1F, {SpiCommandMaxWidth-40{1'b0}}}; // Adjusted for 128x32
                    spi_word_bit_count <= 40;
                    delay <= 1;
                end
                VccEn: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= (ClkFreq * VccEnDelay) / 1000;
                end
                DisplayOn: begin
                    spi_word <= {8'hAF, {SpiCommandMaxWidth-8{1'b0}}};
                    spi_word_bit_count <= 8;
                    delay <= (ClkFreq * StartupCompleteDelay) / 1000;
                end
                PrepareNextFrame: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= 1;
                end
                SetColAddress: begin
                    spi_word <= {24'h15007F, {SpiCommandMaxWidth-24{1'b0}}}; // Columns 0-127
                    spi_word_bit_count <= 24;
                    delay <= 1;
                end
                SetRowAddress: begin
                    spi_word <= {24'h75001F, {SpiCommandMaxWidth-24{1'b0}}}; // Pages 0-3
                    spi_word_bit_count <= 24;
                    delay <= 1;
                end
                WaitNextFrame: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= 0;
                end
                SendPixel: begin
                    spi_word <= {pixel_data, {SpiCommandMaxWidth-16{1'b0}}};
                    spi_word_bit_count <= 16;
                    delay <= 0;
                end
                default: begin
                    spi_word <= 0;
                    spi_word_bit_count <= 0;
                    delay <= 0;
                end
            endcase
        end
    end
end

endmodule