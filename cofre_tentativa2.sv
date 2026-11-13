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

    always_comb begin
        btn_press = ~btn
        btn_unico = btn_press & ~btn_antes
        qualquer_btn = (|btn_unico)
         
