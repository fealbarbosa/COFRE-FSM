module cofre (
    input logic btn[3:1],
    input logic clk,
    input logic rstn,
    output logic [6:0] hex [4:0],
    output logic leds_vermelhos [17:0],
    output logic leds_verdes [8:0]
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
    logic [2:0] btn_antes, btn_unico, btn_press;
    logic qualquer_btn;

    localparam logic [3:0] senha_cofre [0:3] =  {4'b0011, 4'b0101, 4'b0001, 4'b1000};
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
        end
        else begin
            btn_antes <= btn_press;
            estado_atual <= proximo_estado
        end
    end

    always_comb begin
        proximo_estado = estado_atual;


        unique case (estado_atual)

        S0: begin
            if (btn_unico[0]) proximo_estado = S1;
            else proximo_estado = S0;
        end

        S1: begin
            if (btn_unico[0]) proximo_estado = S2;
            else proximo_estado = S1;
        end

        S2: begin
            if (btn_unico[0]) proximo_estado = S3;
            else proximo_estado = S2;
        end

        S3: begin
            if (btn_unico[0]) proximo_estado = DESBLOQUEADO;
            else proximo_estado = S3;
        end

        DESBLOQUEADO: begin
