`default_nettype none

module tt_um_brayan_snake_vga (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    wire hsync, vsync, display_on;
    wire [9:0] hpos, vpos;

    hvsync_generator video (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    // Controles:
    // ui_in[0] izquierda
    // ui_in[1] derecha
    // ui_in[2] arriba
    // ui_in[3] abajo
    // ui_in[4] reiniciar

    wire izquierda = ui_in[0];
    wire derecha   = ui_in[1];
    wire arriba    = ui_in[2];
    wire abajo     = ui_in[3];
    wire reinicio  = ui_in[4];

    wire [5:0] celda_x = hpos[9:4];
    wire [4:0] celda_y = vpos[8:4];

    wire frame_tick = (hpos == 10'd0) && (vpos == 10'd0);

    // Version compacta para que el diseño quepa en un tile 1x1.
    // Serpiente compacta de 4 segmentos para dejar margen de enrutamiento en 1x1.
    reg [5:0] serpiente_x [0:3];
    reg [4:0] serpiente_y [0:3];

    reg [4:0] longitud;
    reg [5:0] comida_x;
    reg [4:0] comida_y;
    reg [1:0] direccion;
    reg [4:0] divisor;
    reg [7:0] lfsr;
    reg [7:0] puntuacion;
    reg game_over;

    integer idx_move;
    integer idx_collision;
    integer idx_render;

    reg [5:0] siguiente_x;
    reg [4:0] siguiente_y;

    always @(*) begin
        siguiente_x = serpiente_x[0];
        siguiente_y = serpiente_y[0];

        case (direccion)
            2'd0: siguiente_x = serpiente_x[0] + 6'd1;
            2'd1: siguiente_y = serpiente_y[0] + 5'd1;
            2'd2: siguiente_x = serpiente_x[0] - 6'd1;
            2'd3: siguiente_y = serpiente_y[0] - 5'd1;
        endcase
    end

    wire choque_pared =
        (siguiente_x >= 6'd40) ||
        (siguiente_y >= 5'd30);

    wire comio =
        (siguiente_x == comida_x) &&
        (siguiente_y == comida_y);

    reg choque_cuerpo;

    always @(*) begin
        choque_cuerpo = 1'b0;

        for (idx_collision = 1; idx_collision < 4; idx_collision = idx_collision + 1) begin
            if ((idx_collision < longitud) &&
                (siguiente_x == serpiente_x[idx_collision]) &&
                (siguiente_y == serpiente_y[idx_collision]))
                choque_cuerpo = 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serpiente_x[0] <= 6'd16;
            serpiente_y[0] <= 5'd15;

            serpiente_x[1] <= 6'd15;
            serpiente_y[1] <= 5'd15;

            serpiente_x[2] <= 6'd14;
            serpiente_y[2] <= 5'd15;

            serpiente_x[3] <= 6'd13;
            serpiente_y[3] <= 5'd15;

            for (idx_move = 4; idx_move < 8; idx_move = idx_move + 1) begin
                serpiente_x[idx_move] <= 6'd0;
                serpiente_y[idx_move] <= 5'd0;
            end

            longitud   <= 5'd2;
            comida_x   <= 6'd28;
            comida_y   <= 5'd15;
            direccion  <= 2'd0;
            divisor    <= 5'd0;
            lfsr       <= 8'hA7;
            puntuacion <= 8'd0;
            game_over  <= 1'b0;
        end else if (frame_tick) begin

            lfsr <= {
                lfsr[6:0],
                lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]
            };

            if (izquierda && direccion != 2'd0)
                direccion <= 2'd2;

            if (derecha && direccion != 2'd2)
                direccion <= 2'd0;

            if (arriba && direccion != 2'd1)
                direccion <= 2'd3;

            if (abajo && direccion != 2'd3)
                direccion <= 2'd1;

            if (reinicio) begin
                serpiente_x[0] <= 6'd16;
                serpiente_y[0] <= 5'd15;

                serpiente_x[1] <= 6'd15;
                serpiente_y[1] <= 5'd15;

                serpiente_x[2] <= 6'd14;
                serpiente_y[2] <= 5'd15;

                serpiente_x[3] <= 6'd13;
                serpiente_y[3] <= 5'd15;

            longitud   <= 5'd2;
                comida_x   <= 6'd28;
                comida_y   <= 5'd15;
                direccion  <= 2'd0;
                divisor    <= 5'd0;
                puntuacion <= 8'd0;
                game_over  <= 1'b0;
            end else if (!game_over) begin

                if (divisor == 5'd7) begin
                    divisor <= 5'd0;

                    if (choque_pared || choque_cuerpo) begin
                        game_over <= 1'b1;
                    end else begin

                        for (idx_move = 3; idx_move > 0; idx_move = idx_move - 1) begin
                            if ((idx_move < longitud) ||
                                (comio && idx_move == longitud)) begin
                                serpiente_x[idx_move] <= serpiente_x[idx_move-1];
                                serpiente_y[idx_move] <= serpiente_y[idx_move-1];
                            end
                        end

                        serpiente_x[0] <= siguiente_x;
                        serpiente_y[0] <= siguiente_y;

                        if (comio) begin
                            if (longitud < 5'd3)
                                longitud <= longitud + 5'd1;

                            puntuacion <= puntuacion + 8'd1;

                            comida_x <=
                                (lfsr[5:0] < 6'd40) ?
                                lfsr[5:0] :
                                lfsr[5:0] - 6'd24;

                            comida_y <=
                                (lfsr[7:3] < 5'd30) ?
                                lfsr[7:3] :
                                lfsr[7:3] - 5'd2;
                        end
                    end
                end else begin
                    divisor <= divisor + 5'd1;
                end
            end
        end
    end

    reg serpiente_pixel;
    reg cabeza_pixel;

    always @(*) begin
        serpiente_pixel = 1'b0;
        cabeza_pixel = 1'b0;

        for (idx_render = 0; idx_render < 4; idx_render = idx_render + 1) begin
            if ((idx_render < longitud) &&
                celda_x == serpiente_x[idx_render] &&
                celda_y == serpiente_y[idx_render])
                serpiente_pixel = 1'b1;

            if ((idx_render == 0) &&
                celda_x == serpiente_x[idx_render] &&
                celda_y == serpiente_y[idx_render])
                cabeza_pixel = 1'b1;
        end
    end

    wire comida_pixel =
        (celda_x == comida_x) &&
        (celda_y == comida_y);

    wire pared_pixel =
        (celda_x == 0) ||
        (celda_x == 39) ||
        (celda_y == 0) ||
        (celda_y == 29);

    wire marcador_pixel =
        (vpos < 10'd8) &&
        (hpos < (10'd8 + puntuacion));

    wire cuadro_game_over =
        game_over &&
        hpos >= 10'd208 &&
        hpos < 10'd432 &&
        vpos >= 10'd200 &&
        vpos < 10'd280;

    wire equis_game_over =
        game_over &&
        (
            (
                ((hpos >= 10'd245) && (hpos < 10'd265)) ||
                ((hpos >= 10'd375) && (hpos < 10'd395))
            ) &&
            (vpos >= 10'd215) &&
            (vpos < 10'd265)
        );

    reg [1:0] rojo;
    reg [1:0] verde;
    reg [1:0] azul;

    always @(*) begin
        rojo = 2'b00;
        verde = 2'b00;
        azul = 2'b00;

        if (!display_on) begin
            rojo = 2'b00;
            verde = 2'b00;
            azul = 2'b00;
        end else if (cuadro_game_over) begin
            rojo = 2'b01;
            verde = 2'b00;
            azul = 2'b01;

            if (equis_game_over) begin
                rojo = 2'b11;
                verde = 2'b11;
                azul = 2'b00;
            end
        end else if (marcador_pixel) begin
            rojo = 2'b11;
            verde = 2'b11;
            azul = 2'b11;
        end else if (cabeza_pixel) begin
            rojo = 2'b11;
            verde = 2'b11;
            azul = 2'b00;
        end else if (serpiente_pixel) begin
            rojo = 2'b00;
            verde = 2'b11;
            azul = 2'b01;
        end else if (comida_pixel) begin
            rojo = 2'b11;
            verde = 2'b00;
            azul = 2'b00;
        end else if (pared_pixel) begin
            rojo = 2'b01;
            verde = 2'b00;
            azul = 2'b11;
        end else begin
            rojo = 2'b00;
            verde = 2'b00;
            azul = 2'b01;
        end
    end

    assign uo_out[0] = rojo[1];
    assign uo_out[4] = rojo[0];

    assign uo_out[1] = verde[1];
    assign uo_out[5] = verde[0];

    assign uo_out[2] = azul[1];
    assign uo_out[6] = azul[0];

    assign uo_out[3] = vsync;
    assign uo_out[7] = hsync;

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire unused = &{ena, uio_in, 1'b0};

endmodule
