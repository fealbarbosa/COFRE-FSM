module bcd_to_7segment_anodo (
    input  logic [3:0] bcd,
    output logic [6:0] seg    // seg[6]=a ... seg[0]=g, ativo em '0' (ânodo comum)
);
    always_comb begin
        case (bcd)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111110; // hífen
        endcase
    end

endmodule




module cofre (
    input logic [3:1] btn,
    input logic clk,
    input logic rstn,
    output logic [6:0] hex [4:0],
    output logic [17:0] leds_vermelhos,
    output logic [8:0] leds_verdes
    );

    // hot-encoding técnica
    typedef enum logic [5:0] {
        S0 = 6'b000001,
        S1 = 6'b000010,
        S2 = 6'b000100,
        S3 = 6'b001000,
        DESBLOQUEADO = 6'b010000,
        SENHA_ERRADA = 6'b100000
    } tipo_de_estado;

    tipo_de_estado estado_atual, proximo_estado;
    logic [3:1] btn_antes, btn_unico, btn_press;
    logic qualquer_btn;
    logic [3:0] digitos [0:3];
    logic [3:0] digito_atual;
    logic senha_ok;
    logic [27:0] temporizador;

    localparam logic [3:0] senha_cofre [0:3] =  '{4'b0011, 4'b0101, 4'b0001, 4'b1000};
    localparam int tempo_desbloqueado = 250_000_000;
    localparam int tempo_senha_errada = 150_000_000;
    

    always_comb begin
        btn_press = ~btn;
        btn_unico = btn_press & ~btn_antes;
        qualquer_btn = (|btn_unico); // TRUE SE AO MENOS UM BIT DE btn_unico FOR 1
    end         

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            btn_antes <= 3'b000;
            estado_atual <= S0;
            digitos[0] <= 4'b0000;
            digitos[1] <= 4'd0;
            digitos[2] <= 4'b0000;
            digitos[3] <= 4'd0;
            temporizador <= 28'b0000000000000000000000000000;
        end
        else begin
            btn_antes <= btn_press;
            estado_atual <= proximo_estado;

   //////// BOTÕES DE INCREMENTO E DECREMENTO AQUI 
            case (estado_atual)

                S0: begin
                    if (btn_unico[2]) begin
                        if (digitos[0] == 9) begin
                            digitos[0] <= 0;
                        end
                        else begin
                            digitos[0] <= digitos[0] + 1;
                        end
                    end

                    else if (btn_unico[3]) begin
                        if (digitos[0] == 0) begin
                            digitos[0] <= 9;
                        end
                        else begin
                            digitos[0] <= digitos[0] - 1;
                        end
                    end
                end
    

                S1: begin
                    if (btn_unico[2]) begin
                        if (digitos[1] == 9) begin
                            digitos[1] <= 0;
                        end
                        else begin
                            digitos[1] <= digitos[1] + 1;
                        end
                    end

                    else if (btn_unico[3]) begin
                        if (digitos[1] == 0) begin
                            digitos[1] <= 9;
                        end
                        else begin
                            digitos[1] <= digitos[1] - 1;
                        end
                    end 
                end


                S2: begin
                    if (btn_unico[2]) begin
                        if (digitos[2] == 9) begin
                            digitos[2] <= 4'b0000;
                        end
                        else begin
                            digitos[2] <= digitos[2] + 1;
                        end
                    end

                    else if (btn_unico[3]) begin
                        if (digitos[2] == 0) begin
                            digitos[2] <= 9;
                        end
                        else begin
                            digitos[2] <= digitos[2] - 1;
                        end
                    end
                end


                S3: begin
                    if (btn_unico[2]) begin
                        if (digitos[3] == 9) begin
                            digitos[3] <= 4'b0000;
                        end
                        else begin
                            digitos[3] <= digitos[3] + 1;
                        end
                    end
                    
                    else if (btn_unico[3]) begin
                        if (digitos[3] == 0) begin
                            digitos[3] <= 9;
                        end
                        else begin
                            digitos[3] <= digitos[3] - 1;
                        end
                    end

                    else if (btn_unico[1] && ~btn_unico[2] && ~btn_unico[3]) begin
                        if (senha_ok) begin
                            temporizador <= tempo_desbloqueado;
                        end
                        else begin
                            temporizador <= tempo_senha_errada;
                        end
                    end
                end


                DESBLOQUEADO: begin
                    if (temporizador>0) begin
                        temporizador <= temporizador - 1;
                    end
                    else begin
                        digitos[0] <= 0;
                        digitos[1] <= 0;
                        digitos[2] <= 0;
                        digitos[3] <= 0;
                    end
                end


                SENHA_ERRADA: begin
                    if (temporizador>0) begin
                        temporizador <= temporizador - 1;
                    end
                    else begin
                        digitos[0] <= 0;
                        digitos[1] <= 0;
                        digitos[2] <= 0;
                        digitos[3] <= 0;
                    end
                end
            endcase
        end
    end

//CHECAGEM DA SENHA OK
    always_comb begin
        senha_ok =  (digitos[0] == senha_cofre[0]) &&
                    (digitos[1] == senha_cofre[1]) &&
                    (digitos[2] == senha_cofre[2]) &&
                    (digitos[3] == senha_cofre[3]);
    end

    always_comb begin
        proximo_estado = estado_atual;
        leds_verdes = 0;
        leds_vermelhos = 0;

        unique case (estado_atual)

            S0: begin
                if (btn_unico[1] && ~btn_unico[2] && ~btn_unico[3]) proximo_estado = S1;
                else proximo_estado = S0;
            end

            S1: begin
                if (btn_unico[1] && ~btn_unico[2] && ~btn_unico[3]) proximo_estado = S2;
                else proximo_estado = S1;
            end

            S2: begin
                if (btn_unico[1] && ~btn_unico[2] && ~btn_unico[3]) proximo_estado = S3;
                else proximo_estado = S2;
            end

            S3: begin
                if (senha_ok && btn_unico[1] && ~btn_unico[2] && ~btn_unico[3]) proximo_estado = DESBLOQUEADO;
                else if (~senha_ok && btn_unico[1] && ~btn_unico[2] && ~btn_unico[3])proximo_estado = SENHA_ERRADA;
                else proximo_estado = S3;
            end

            DESBLOQUEADO: begin
                leds_verdes = 9'b111111111;
                if (temporizador == 0) begin
                    proximo_estado = S0;
                end
            end

            SENHA_ERRADA: begin
                leds_vermelhos = 18'b111111111111111111;
                if (temporizador == 0) begin
                    proximo_estado = S0;
                end
            end

            default: begin
                proximo_estado = S0;
            end

        endcase
    end


    always_comb begin
        case(estado_atual)

            S0: digito_atual = 1;
            S1: digito_atual = 2;
            S2: digito_atual = 3;
            S3: digito_atual = 4;
            default: digito_atual = 12;
        endcase
    end


    bcd_to_7segment_anodo decode0 (
        .bcd(digitos[0]),
        .seg(hex[3])
    );

    bcd_to_7segment_anodo decode1 (
        .bcd(digitos[1]),
        .seg(hex[2])
    );

    bcd_to_7segment_anodo decode2 (
        .bcd(digitos[2]),
        .seg(hex[1])
    );

    bcd_to_7segment_anodo decode3 (
        .bcd(digitos[3]),
        .seg(hex[0])
    );

    bcd_to_7segment_anodo decode4 (
        .bcd(digito_atual),
        .seg(hex[4])
    );

endmodule