module cofre (
	input logic clk, //ENTRADA DE CLOCK DA PLACA
	input logic rstn, // BOTÃO DE RESET (KEY[0]) "n" depois de "rst" significa que ele é tido como ativo quando em 0.
	input logic [3:0] btn, //BOTÕES DE CONTROLE DO SISTEMA (KEY[0]..KEY[3])
	output logic unlocked, //OUTPUT EM RELAÇÃO AO SUCESSO EM DESBLOQUEAR O COFRE

    // OUTPUTS PARA OS 5 DISPLAYS DE 7 SEGMENTOS
    // CADA UM PRECISA DE 7 BITS, 1 BIT PARA CADA SEGMENTO, JUNÇÃO DE BITS FORMAM UM NÚMERO NO DISPLAY
    output logic [6:0] hex4, // MOSTRA QUAL DÍGITO ESTÁ SENDO ALTERADO (1-4)
    output logic [6:0] hex3, // OUTPUT FEEDBACK DO PRIMEIRO DÍGITO DA SENHA
    output logic [6:0] hex2, // OUTPUT FEEDBACK DO SEGUNDO DÍGITO DA SENHA
    output logic [6:0] hex1, // OUTPUT FEEDBACK DO TERCEIRO DÍGITO DA SENHA
    output logic [6:0] hex0, // OUTPUT FEEDBACK DO QUARTO DÍGITO DA SENHA

    output logic [8:0] LEDG,
    output logic [17:0] LEDR

);
integer x_reset; // declaração de x como um inteiro para ser usado no for do reset
integer x_compare; // x variável para comparação

// CRIANDO TIPO PERSONALIZADO PARA ESTADOS DA MÁQUINA
typedef enum logic [1:0]{
    INPUT,
    DESBLOQUEADO,
    ERRO
} estado_tipo;
// COLOCANDO A VARIÁVEL ESTADO_ATUAL COMO UMA QUE RECEBE UMA DAS TRÊS SITUAÇÕES LISTADAS NO TIPO PERSONALIZADO.
estado_tipo estado_atual; 


// ========================= SENHA DO COFRE =============================
localparam logic [3:0] senha_cofre [0:3] = '{4'b0011, 4'b0101, 4'b0000, 4'b1000}; 
// ========================= SENHA DO COFRE =============================

// CONTADOR
localparam integer tempo_desbloqueado = 250_000_000; // TEMPO DE ESPERA APÓS O SISTEMA ENTRAR NO ESTADO DE DESBLOQUEIO COM SUCESSO ANTES DE RESETAR (250M ciclos de clock)
localparam integer tempo_erro = 150_000_000; // TEMPO DE ESPERA APÓS O SISTEMA ENTRAR NO ESTADO DE SENHA INCORRETA ANTES DE RESETAR (150M ciclos de clock)


logic senha_ok;
logic [27:0] contador;
logic [3:0] posicao_botao; //VARIÁVEL QUE REPRESENTA O ESTADO ATUAL IMEDIATO DOS BOTÕES
logic [3:0] antes_botao; //VARIÁVEL QUE REPRESENTA O ESTADO ANTERIOR DOS BOTÕES
logic [3:0] alerta_botao; //VARIÁVEL QUE REPRESENTA O MOMENTO EM QUE ALGUÉM APERTA O BOTÃO (É O QUE DE FATO REALIZA AÇÕES NO SISTEMA)
logic reset_ativo; //VARIÁVEL QUE REPRESENTA O RESET PRESSIONADO
logic [3:0] inseridos [0:3]; // variável para guardar números que vão de 0 a 9, com 4 bits disponíveis.
// a declaração logic com 4 bits permite guardar 4 estados em que eses números podem ser armazenados. É como uma caixa com 4 posições para guardar mais 4 caixas dentro.
logic [1:0] digito_atual; // variável que guarda o índice do digito atual sendo digitado, dois bits são suficientes (0,1,2,3).

assign reset_ativo = ~rstn; // NEGAÇÃO DO RESET, PARA SIMBOLIZAR RESET ATIVO
assign posicao_botao = ~btn; //INVERSÃO DO SINAL DAS ENTRADAS BOTÕES POR ELES SEREM DE NÍVEL BAIXO, TAL QUAL O DO RESET

// DISPLAYS HEX DA PLACA RECEBENDO O DECODIFICADOR DE BINÁRIO PARA SEGMENTOS
assign hex4 = decodificado({2'b00, digito_atual} + 4'b0001); // CONCATENAÇÃO AQUI SERVE PARA COMPLETAR COM ZEROS OS OUTROS DOIS MAIS À ESQUERDA BITS QUE A FUNÇÃO ESPERA E PEGAR OS DOIS ÚLTIMOS DE DIGITO_ATUAL
assign hex3 = decodificado(inseridos[0]);
assign hex2 = decodificado(inseridos[1]);
assign hex1 = decodificado(inseridos[2]);
assign hex0 = decodificado(inseridos[3]);


always_comb begin //LÓGICA COMBINACIONAL: NÃO DEPENDE DE CLOCK; IMEDIATO; SEMPRE CHECADO E APLICADO
	alerta_botao = posicao_botao & ~antes_botao; /* 
    O ALERTA DE PRESSIONAMENTO É ATIVADO SE E SOMENTE SE O BOTÃO FOR PRESSIONADO E NÃO HOUVER 
    PRESSIONAMENTO NO CLOCK ANTERIOR. ISSO EVITA QUE CADA CLOCK EM QUE O BOTÃO ESTIVER PRESSIONADO
    SEJA LIDO COMO UM NOVO INPUT.
*/
     
end

always_ff @(posedge clk or negedge rstn) begin
    /*
    ANÁLISE SEQUENCIAL. TEM MEMÓRIA E DEPENDE DA ALTERACÃO DO CLOCK POSITIVO (posedge clk) OU DA DESCIDA DO SINAL DE RESET
    */

    if (reset_ativo) begin
        antes_botao <= 4'b1111;
    end
    else begin
        antes_botao <= posicao_botao; /* 
        CASO CONTRÁRIO, GUARDA O SINAL DE PRESSIONAMENTO DO BOTÃO ATUAL NA MEMÓRIA, ESTRUTURA DE REGISTRADOR. */
    end
end

 // SISTEMA DE RESET DO COFRE
always_ff @(posedge clk or negedge rstn) begin
    if (reset_ativo) begin
        unlocked <= 1'b0; // STATUS DE UNLOCKED VOLTA PARA ZERO
        for (x_reset=0; x_reset<4; x_reset = x_reset + 1) begin // instruções que vão se repetir quatro vezes. x vai assumir o valor de 0 até 3
            inseridos[x_reset] <= 4'b0000; // reseta cada número armazenado na memória, todos os quatro digitos da senha para 0 novamente.
        end
        digito_atual <= 2'b00; // INDÍCE DE FASE ATUAL TAMBÉM É RESETADO
        estado_atual <= INPUT; //ESTADO VOLTA PARA ESPERAR O INPUT DO USUÁRIO
        contador <= 28'd0; // CONTADOR ZERADO NO RESET
    end

    else begin
        if (estado_atual == INPUT) begin
            contador <= 28'd0; // CONTADOR ZERADO ENQUANTO ESTIVER NO INPUT
            //LÓGICA DE INCREMENTAÇÃO DO DIGITO ATUAL SENDO EDITADO
            if (alerta_botao[2]) begin //CASO O BOTÃO DE INCREMENTO SEJA PRESSIONADO
                
                if (inseridos[digito_atual] < 9) begin //SE O DIGITO ATUAL SEJA MENOR QUE NOVE
                inseridos[digito_atual] <= inseridos[digito_atual] + 1; //INCREMENTA 1 NO DIGITO 
                end

                else begin //CASO O DIGITO SEJA O NÚMERO 9
                    inseridos[digito_atual] <= 4'b0000; //RETORNA AO ZERO
                end
            end

            //LÓGICA DE DECREMENTO
            else if (alerta_botao[3]) begin //CASO O BOTÃO DE DECREMENTO SEJA PRESSIONADO
                if (inseridos[digito_atual]>0) begin //SE O NÚMERO EXIBIDO FOR MAIOR QUE ZERO
                    inseridos[digito_atual] <= inseridos[digito_atual] - 1; //VOLTA UM NÚMERO PARA A ESQUERDA
                end

                else begin // SE O NÚMERO FOR ZERO
                    inseridos[digito_atual] <= 4'b1001; //VAI PARA O NÚMERO 9
                end
            end

            // LÓGICA DE CONFIRMAÇÃO DO DIGITO SELECIONADO
            else if (alerta_botao[1]) begin // SE O BOTÃO DE 'CONFIRMAR' FOR PRESSIONADO...
                if (digito_atual<3) begin //SE A POSIÇÃO DO DIGITO FOR NO MÁXIMO O TERCEIRO
                    digito_atual <= digito_atual + 1; //PASSA PARA O PRÓXIMO ALGARISMO
                end 
                else begin //SE O DÍGITO FOR O ÚLTIMO DAS POSIÇÕES PARA A SENHA
                    if (senha_ok) begin //CASO A SENHA ESTEJA CORRETA
                        unlocked <= 1'b1; // UNLOCKED ON
                        estado_atual <= DESBLOQUEADO; // ESTADO RECEBE UNLOCKED DEFINIDO NO TYPEDEF
                        contador <= 28'd0; // TEMPO DE ESPERA APÓS DESBLOQUEAR COM SUCESSO O COFRE
                       
                    end
                    else begin // SE A SENHA ESTIVER ERRADA
                        unlocked <= 1'b0; // UNLOCKED RECEBE ZERO
                        estado_atual <= ERRO; //ESTADO DA MÁQUINA RECEBE ERRO DEFINIDO NO TYPEDEF
                        contador <= 28'd0; // TEMPO DE ESPERA APÓS ERRO
                        
                    end
                end
            end
        end
        else if (estado_atual == DESBLOQUEADO) begin
            contador <= contador + 1'b1; // A PARTIR DO ESTADO DE DESBLOQUEADO, O CONTADOR COMEÇA A FAZER A CONTAGEM A CADA CLOCK

            if (contador >= tempo_desbloqueado) begin
                estado_atual <= INPUT;
                contador <= 28'd0;
                unlocked <= 1'b0;
                digito_atual <= 2'b00;

                for (x_reset=0; x_reset < 4; x_reset = x_reset + 1) begin
                    inseridos[x_reset] <= 4'b0000;
                end
            end

        end
        else if (estado_atual == ERRO) begin
            contador <= contador + 1'b1; // MESMA COISA DE QUANDO É DESBLOQUEADO, APENAS MENOS TEMPO DE ESPERA

            if (contador >= tempo_erro) begin
                estado_atual <= INPUT;
                contador <= 28'd0;
                unlocked <= 1'b0;
                digito_atual <= 2'b00;

                for (x_reset=0; x_reset < 4; x_reset = x_reset + 1) begin
                    inseridos[x_reset] <= 4'b0000;
                end
            end
        end
    end
end

always_comb begin
//CHECAGEM DA SENHA CORRETA OU ERRADA
    senha_ok = 1'b1; 
    for (x_compare=0; x_compare<4; x_compare = x_compare + 1) begin
        if (inseridos[x_compare] != senha_cofre[x_compare]) begin
            senha_ok = 1'b0;
        end
    end
end

//FUNÇÃO QUE CONVERTE (DECODIFICA) UN NÚMERO BINÁRIO EM SEGMENTOS DO HEX DISPLAY
function automatic logic [6:0] decodificado( //OS 7 BITS QUE REPRESENTAM OS 7 SEGMENTOS DO DISPLAY
    input logic [3:0] valor
);
    begin
        case (valor)
            4'b0000: decodificado = 7'b1000000;
            4'b0001: decodificado = 7'b1111001; 
            4'b0010: decodificado = 7'b0100100; 
            4'b0011: decodificado = 7'b0110000; 
            4'b0100: decodificado = 7'b0011001; 
            4'b0101: decodificado = 7'b0010010; 
            4'b0110: decodificado = 7'b0000010; 
            4'b0111: decodificado = 7'b1111000; 
            4'b1000: decodificado = 7'b0000000; 
            4'b1001: decodificado = 7'b0010000; 
            default: decodificado = 7'b1111111;
        endcase
    end
endfunction

always_comb begin
    if (estado_atual == DESBLOQUEADO) begin // QUANDO DESBLOQUEADO, LEDS VERDES ACENDEM E VERMELHOS FICAM EM ZERO
        LEDG = 9'b111111111;
        LEDR = 18'b000000000000000000;
    end
    else if (estado_atual == ERRO) begin // QUANDO EM ESTADO DE ERRO, LEDS VERMELHOS ACENDEM E VERDES FICAM EM ZERO
        LEDG = 9'b000000000;
        LEDR = 18'b111111111111111111;
    end
    else begin // QUANDO EM ESTADO DE INPUT, TODOS OS LEDS FICAM EM ZERO
        LEDG = 9'b000000000;
        LEDR = 18'b000000000000000000;
    end
end
endmodule