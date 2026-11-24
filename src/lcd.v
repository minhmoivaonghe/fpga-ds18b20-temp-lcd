module hehe (
    input  wire clk,
    input  wire rst,
    inout  wire ds18b20,
    output reg [11:0] nhietdo,
    output reg ds_pre,
    output reg led
);
    reg [7:0] ml_skip_rom = 8'hCC;
    reg [7:0] ml_convert  = 8'h44;
    reg [7:0] ml_read_ram = 8'hBE;

    localparam [3:0]
        reset      = 4'd0,
        skip_rom   = 4'd1,
        write_byte = 4'd2,
        write_bit0 = 4'd3,
        write_bit1 = 4'd4,
        read_bit   = 4'd5,
        convert_t  = 4'd6,
        read_scrat = 4'd7,
        get_temp   = 4'd8,
        wait_750ms = 4'd9,
        wait_4ms   = 4'd10;

    reg [3:0]  state = 4'd0;
    reg [25:0] j     = 0;
    reg [3:0]  k     = 0;
    reg [1:0]  tt    = 0;
    reg [1:0]  tt_rst;
    reg        tt_wr_b0;
    reg        tt_wr_b1;
    reg [1:0]  tt_rd_b;

    reg        ds_in;
    reg        ds_out;
    reg        ds_ena;
    reg [7:0]  dlg   = 0;
    reg [11:0] dln   = 0;
    localparam WAIT_750MS = 26'd37_500_000;
    assign ds18b20 = (ds_ena == 1) ? ds_out : 1'bz;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= reset;
            tt_wr_b0  <= 0;
            tt_wr_b1  <= 0;
            tt_rd_b   <= 0;
            tt_rst    <= 0;
            k         <= 0;
            tt        <= 0;
            j         <= 0;
            dlg       <= 8'h01;
            ds_ena    <= 0;
            ds_out    <= 1;
        end
        else begin
            case (state)

                reset: begin
                    if (tt_rst == 0) begin
                        ds_ena <= 1;
                        ds_out <= 0;
                        if (j < 25000) j <= j + 1;
                        else begin j <= 0; tt_rst <= 1; end
                    end
                    else if (tt_rst == 1) begin
                        ds_ena <= 0;
                        if (j < 500) j <= j + 1;
                        else begin j <= 0; tt_rst <= 2; end
                    end
                    else if (tt_rst == 2) begin
                        ds_ena <= 0;
                        if (j < 12000) j <= j + 1;
                        else begin j <= 0; tt_rst <= 3; end
                        if (j == 3000) begin
                            ds_in  <= ds18b20;
                            ds_pre <= ds18b20;
                        end
                    end
                    else if (tt_rst == 3) begin
                        tt_rst <= 0;
                        state  <= (ds_in == 0) ? skip_rom : reset;
                    end
                end

                skip_rom: begin
                    led <= 1;
                    dlg <= ml_skip_rom;
                    k   <= 0;
                    state <= write_byte;
                end

                write_byte: begin
                    if (k < 8) begin
                        state <= (dlg[k] == 0) ? write_bit0 : write_bit1;
                        k     <= k + 1;
                    end
                    else begin
                        k <= 0;
                        case (tt)
                            2'd0: begin
                                tt    <= 2'd1;
                                state <= convert_t;
                            end
                            2'd1: begin
                                tt    <= 2'd2;
                                state <= wait_750ms;
                            end
                            2'd2: begin
                                tt    <= 2'd3;
                                state <= read_scrat;
                            end
                            2'd3: begin
                                tt    <= 2'd0;
                                state <= get_temp;
                            end
                        endcase
                    end
                end

                write_bit0: begin
                    if (tt_wr_b0 == 0) begin
                        ds_out <= 0; ds_ena <= 1;
                        if (j < 3500) j <= j + 1;
                        else begin j <= 0; tt_wr_b0 <= 1; end
                    end
                    else begin
                        ds_ena <= 0;
                        if (j < 250) j <= j + 1;
                        else begin j <= 0; tt_wr_b0 <= 0; state <= write_byte; end
                    end
                end

                write_bit1: begin
                    if (tt_wr_b1 == 0) begin
                        ds_out <= 0; ds_ena <= 1;
                        if (j < 400) j <= j + 1;
                        else begin j <= 0; tt_wr_b1 <= 1; end
                    end
                    else begin
                        ds_ena <= 0;
                        if (j < 3600) j <= j + 1;
                        else begin j <= 0; tt_wr_b1 <= 0; state <= write_byte; end
                    end
                end

                read_bit: begin
                    if (tt_rd_b == 0) begin
                        ds_out <= 0; ds_ena <= 1;
                        if (j < 200) j <= j + 1;
                        else begin j <= 0; tt_rd_b <= 1; end
                    end
                    else if (tt_rd_b == 1) begin
                        ds_ena <= 0;
                        if (j < 200) j <= j + 1;
                        else begin j <= 0; tt_rd_b <= 2; end
                    end
                    else if (tt_rd_b == 2) begin
                        ds_in  <= ds18b20;
                        ds_ena <= 0;
                        if (j < 50) j <= j + 1;
                        else begin j <= 0; tt_rd_b <= 3; end
                    end
                    else begin
                        ds_ena <= 0;
                        if (j < 2750) j <= j + 1;
                        else begin j <= 0; tt_rd_b <= 0; state <= get_temp; end
                    end
                end

                convert_t: begin
                    dlg   <= ml_convert;
                    k     <= 0;
                    state <= write_byte;
                end

                wait_750ms: begin
                    if (j < WAIT_750MS) begin
                        j <= j + 1;
                    end
                    else begin
                        j     <= 0;
                        state <= reset;
                    end
                end

                read_scrat: begin
                    dlg   <= ml_read_ram;
                    k     <= 0;
                    state <= write_byte;
                end

                get_temp: begin
                    if (k == 0) begin
                        state <= read_bit;
                        k <= k + 1;
                    end
                    else if (k < 12) begin
                        dln[k - 1] <= ds_in;
                        state  <= read_bit;
                        k      <= k + 1;
                    end
                    else begin
                        k       <= 0;
                        nhietdo <= dln;
                        state   <= wait_4ms;
                    end
                end

                wait_4ms: begin
                    if (j < 200_000) begin
                        j <= j + 1;
                    end
                    else begin
                        j     <= 0;
                        state <= reset;
                    end
                end
                default: state <= reset;
            endcase
        end
    end
endmodule

module ds18b20_12bit_to_decimal (
    input      [11:0] temp_12bit,
    output reg [3:0]  hundreds,
    output reg [3:0]  tens,
    output reg [3:0]  units,
    output reg [3:0]  frac_digit,
    output wire       is_negative
);
    wire       sign     = temp_12bit[11];
    wire [6:0] int_bits = temp_12bit[10:4];
    wire [3:0] frac     = temp_12bit[3:0];

    assign is_negative = sign;

    wire [6:0] abs_int = sign ? (~int_bits + 1'b1) : int_bits;

    always @(*) begin
        hundreds  = abs_int / 100;
        tens      = (abs_int % 100) / 10;
        units     = abs_int % 10;

        case (frac)
            4'h0: frac_digit = 0;
            4'h1: frac_digit = 1;
            4'h2: frac_digit = 1;
            4'h3: frac_digit = 2;
            4'h4: frac_digit = 3;
            4'h5: frac_digit = 3;
            4'h6: frac_digit = 4;
            4'h7: frac_digit = 4;
            4'h8: frac_digit = 5;
            4'h9: frac_digit = 6;
            4'hA: frac_digit = 6;
            4'hB: frac_digit = 7;
            4'hC: frac_digit = 8;
            4'hD: frac_digit = 8;
            4'hE: frac_digit = 9;
            4'hF: frac_digit = 9;
            default: frac_digit = 0;
        endcase
    end

endmodule

module lcd(
    input  clock,
    output LCD_EN,
    output LCD_RS,
    output LCD_RW,
    inout  [7:0] LCD_DATA,
    input  wire clk,
    input  wire rst,
    inout  wire ds18b20
);

reg        en;
reg [8:0]  data;
reg [6:0]  state;
reg [2:0]  step;
reg [19:0] clk1;
reg [19:0] clk1_count;

wire [11:0] nhietdo_wire;
wire [3:0]  cham, chuc, donvi, tp;
wire        am;

assign LCD_EN   = en;
assign LCD_RS   = data[8];
assign LCD_RW   = 1'b0;
assign LCD_DATA = data[7:0];

assign am = nhietdo_wire[11];

hehe dut (
    .clk(clock),
    .ds18b20(ds18b20),
    .nhietdo(nhietdo_wire)
);

ds18b20_12bit_to_decimal convert_dut (
    .temp_12bit(nhietdo_wire),
    .hundreds(cham),
    .tens(chuc),
    .units(donvi),
    .frac_digit(tp)
);

initial begin
    en          <= 1'b0;
    clk1        <= 20'd30000;
    clk1_count  <= 20'd0;
    data        <= 9'h000;
    state       <= 7'd0;
    step        <= 3'd0;
end

always @(posedge clock) begin
    if (clk1_count < clk1)
        clk1_count <= clk1_count + 1;
    else
        clk1_count <= 0;
end

always @(posedge clock) begin
    if (state < 7'd100) begin
        case (step)
            3'd0: begin
                if (clk1_count == clk1) begin
                    en   <= 1'b1;
                    clk1 <= 20'd50;
                    step <= step + 1;
                end
            end
            3'd1: begin
                if (clk1_count == clk1) begin
                    en   <= 1'b0;
                    clk1 <= 20'd30_000;
                    step <= 3'd0;

                    if (state == 7'd26)
                        state <= 7'd18;
                    else
                        state <= state + 1;
                end
            end
            default: step <= 3'd0;
        endcase
    end
end

always @(posedge clock) begin
    case (state)
        7'd0:  data <= 9'h030;
        7'd1:  data <= 9'h030;
        7'd2:  data <= 9'h030;
        7'd3:  data <= 9'h038;
        7'd4:  data <= 9'h00C;
        7'd5:  data <= 9'h001;
        7'd6:  data <= 9'h006;

        7'd7:  data <= 9'h080;
        7'd8:  data <= 9'h14E;
        7'd9:  data <= 9'h168;
        7'd10: data <= 9'h169;
        7'd11: data <= 9'h165;
        7'd12: data <= 9'h174;
        7'd13: data <= 9'h120;
        7'd14: data <= 9'h164;
        7'd15: data <= 9'h16F;
        7'd16: data <= 9'h13A;
        7'd17: data <= 9'h120;
        7'd18: data <= 9'h08A;
        7'd19: data <= am ? 9'h12D : (cham > 0 || chuc > 0 || donvi > 0) ? 9'h120 : 9'h120;
        7'd20: data <= (cham > 0) ? (9'h130 + {5'b0, cham}) : 9'h120;
        7'd21: data <= (cham > 0 || chuc > 0) ? (9'h130 + {5'b0, chuc}) : 9'h120;
        7'd22: data <= 9'h130 + {5'b0, donvi};
        7'd23: data <= 9'h12E;
        7'd24: data <= 9'h130 + {5'b0, tp};
        7'd25: data <= 9'h120;
        7'd26: data <= 9'h15E;

        default: data <= 9'h000;
    endcase
end

endmodule