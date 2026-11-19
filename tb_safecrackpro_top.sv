`timescale 1ns/1ps

// Testbench para o modulo cofre (cofre.sv)
// Execute no ModelSim/Questa (via Quartus) compilando cofre.sv e simulando este modulo.
//
// Mapeamento de botoes (ativo baixo no hardware, btn_press = ~btn no cofre):
//   btn[1] = avancar posicao (confirma o digito / ultima posicao confere a senha)
//   btn[2] = incrementar digito
//   btn[3] = decrementar digito
//
// Senha correta: 3-5-1-8  (digitos[0..3] = 3,5,1,8)
//
// Mapeamento dos displays de 7 segmentos (hex):
//   hex[3] = digitos[0]   hex[2] = digitos[1]   hex[1] = digitos[2]   hex[0] = digitos[3]
//   hex[4] = posicao atual (1 a 4)
//
// Para evitar simular centenas de milhoes de ciclos nos estados de espera dos LEDs,
// o testbench forca o temporizador interno a zero (via 'force').

module tb_safecrackpro_top;

    // -----------------------------------------------------------------
    // Parametros e sinais
    // -----------------------------------------------------------------
    localparam int CLK_PERIOD = 20; // 20 ns -> 50 MHz

    // Codificacao one-hot dos estados do cofre
    localparam logic [5:0] ST_S0           = 6'b000001;
    localparam logic [5:0] ST_S1           = 6'b000010;
    localparam logic [5:0] ST_S2           = 6'b000100;
    localparam logic [5:0] ST_S3           = 6'b001000;

    logic        clk;
    logic        rstn;
    logic [3:1]  btn;
    logic [6:0]  hex [4:0];
    logic [17:0] leds_vermelhos;
    logic [8:0]  leds_verdes;

    // Todos os digitos concatenados (o cofre usa um array nao empacotado)
    logic [15:0] todos_digitos;
    assign todos_digitos = {dut.digitos[3], dut.digitos[2], dut.digitos[1], dut.digitos[0]};

    // -----------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------
    cofre dut (
        .btn            (btn),
        .clk            (clk),
        .rstn           (rstn),
        .hex            (hex),
        .leds_vermelhos (leds_vermelhos),
        .leds_verdes    (leds_verdes)
    );

    // -----------------------------------------------------------------
    // Clock
    // -----------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------------
    // Contadores de resultado
    // -----------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0, test_num = 0;

    task automatic check(input string nome, input logic condicao);
        test_num++;
        if (condicao) begin
            $display("  [PASS] #%0d: %s", test_num, nome);
            pass_cnt++;
        end else begin
            $display("  [FAIL] #%0d: %s  (t=%0t ns)", test_num, nome, $time);
            fail_cnt++;
        end
    endtask

    // -----------------------------------------------------------------
    // Tarefa: reset
    // -----------------------------------------------------------------
    task do_reset();
        rstn = 1'b0;
        btn  = 3'b111; // sem botao pressionado (ativo baixo -> todos em '1')
        repeat(4) @(posedge clk);
        @(negedge clk); rstn = 1'b1;  // libera reset na borda negativa
        @(posedge clk);                // cofre em S0
    endtask

    // -----------------------------------------------------------------
    // Tarefa: pressionar botao
    //
    // btn_mask: mascara com os bits 'ativos' em nivel alto
    //           (3'b001 = btn[1], 3'b010 = btn[2], 3'b100 = btn[3]).
    //           A tarefa inverte para gerar o nivel baixo ativo no hardware.
    // hold_cycles: numero de bordas positivas que o botao fica pressionado.
    //              3 ciclos e suficiente para qualquer transicao de estado.
    // -----------------------------------------------------------------
    task automatic press_btn(input logic [2:0] btn_mask, input int hold_cycles = 3);
        @(negedge clk);
        btn = ~btn_mask;               // logica invertida: ativo baixo
        repeat(hold_cycles) @(posedge clk);
        @(negedge clk);
        btn = 3'b111;                  // soltar botao
        @(posedge clk);                // ciclo extra para estabilizar
    endtask

    // -----------------------------------------------------------------
    // Tarefa: pular a espera dos LEDs
    //
    // Forca o temporizador interno a 0 para que o cofre saia imediatamente do
    // estado DESBLOQUEADO ou SENHA_ERRADA sem aguardar a contagem completa.
    // -----------------------------------------------------------------
    task skip_led_wait();
        force dut.temporizador = '0;
        @(posedge clk);                // DESBLOQUEADO/SENHA_ERRADA -> S0 (digitos zerados)
        release dut.temporizador;
        @(posedge clk);                // ciclo extra para estabilizar em S0
    endtask

    // -----------------------------------------------------------------
    // Sequencia principal de testes
    // -----------------------------------------------------------------
    initial begin
        $display("================================================");
        $display("   SafeCrackPro - Testbench ModelSim");
        $display("================================================");

        // =============================================================
        // TESTE 1: Reset
        // =============================================================
        $display("\n[Teste 1] Reset inicial");
        do_reset();

        check("Digitos todos zerados apos reset",
              todos_digitos == 16'h0000);
        check("Posicao inicial = 0 (estado S0)",
              dut.estado_atual == ST_S0);
        check("LEDs vermelhos apagados",   leds_vermelhos == 18'h00000);
        check("LEDs verdes apagados",      leds_verdes    == 9'h000);
        // hex[4] deve exibir '1' (posicao 0 + 1): 7-seg ativo-baixo = 7'b1001111
        check("hex[4] exibe posicao 1", hex[4] == 7'b1001111);
        // hex[3..0] devem exibir '0': 7'b0000001
        check("hex[3] exibe '0'", hex[3] == 7'b0000001);
        check("hex[2] exibe '0'", hex[2] == 7'b0000001);
        check("hex[1] exibe '0'", hex[1] == 7'b0000001);
        check("hex[0] exibe '0'", hex[0] == 7'b0000001);

        // =============================================================
        // TESTE 2: Incrementar digito (btn[2])
        // =============================================================
        $display("\n[Teste 2] Incremento de digito - btn[2]");

        press_btn(3'b010); // INC_DIGIT: digito[0] 0 -> 1
        check("Digito[0] = 1 apos 1 press btn[2]",
              dut.digitos[0] == 4'd1);
        check("hex[3] exibe '1' (7'b1001111)",
              hex[3] == 7'b1001111);

        press_btn(3'b010); // INC_DIGIT: digito[0] 1 -> 2
        check("Digito[0] = 2 apos 2 presses btn[2]",
              dut.digitos[0] == 4'd2);
        check("hex[3] exibe '2' (7'b0010010)",
              hex[3] == 7'b0010010);

        // =============================================================
        // TESTE 3: Decrementar digito (btn[3])
        // =============================================================
        $display("\n[Teste 3] Decremento de digito - btn[3]");

        press_btn(3'b100); // DEC_DIGIT: digito[0] 2 -> 1
        check("Digito[0] = 1 apos DEC_DIGIT",
              dut.digitos[0] == 4'd1);
        check("hex[3] exibe '1' (7'b1001111)",
              hex[3] == 7'b1001111);

        // =============================================================
        // TESTE 4: Wrap-around decremento 0 -> 9
        // =============================================================
        $display("\n[Teste 4] Wrap-around DEC: 0 -> 9");

        press_btn(3'b100); // 1 -> 0
        press_btn(3'b100); // 0 -> 9 (wrap)
        check("Digito[0] = 9 apos wrap-around DEC",
              dut.digitos[0] == 4'd9);
        check("hex[3] exibe '9' (7'b0000100)",
              hex[3] == 7'b0000100);

        // =============================================================
        // TESTE 5: Wrap-around incremento 9 -> 0
        // =============================================================
        $display("\n[Teste 5] Wrap-around INC: 9 -> 0");

        press_btn(3'b010); // 9 -> 0 (wrap)
        check("Digito[0] = 0 apos wrap-around INC",
              dut.digitos[0] == 4'd0);
        check("hex[3] exibe '0' (7'b0000001)",
              hex[3] == 7'b0000001);

        // =============================================================
        // TESTE 6: Senha correta - sequencia 3-5-1-8
        // =============================================================
        $display("\n[Teste 6] Senha correta: 3-5-1-8");
        do_reset();

        // Posicao 0: colocar digito 3
        press_btn(3'b010); press_btn(3'b010); press_btn(3'b010); // 0 -> 1 -> 2 -> 3
        check("Pos0: digito[0] = 3",
              dut.digitos[0] == 4'd3);

        // Avancar para posicao 1
        press_btn(3'b001);                          // INC_POSITION: 0 -> 1
        check("Posicao = 1 (estado S1)",
              dut.estado_atual == ST_S1);
        check("hex[4] exibe '2' (7'b0010010)",
              hex[4] == 7'b0010010);

        // Posicao 1: colocar digito 5
        press_btn(3'b010); press_btn(3'b010); press_btn(3'b010);
        press_btn(3'b010); press_btn(3'b010);       // 0 -> 1 -> 2 -> 3 -> 4 -> 5
        check("Pos1: digito[1] = 5",
              dut.digitos[1] == 4'd5);

        // Avancar para posicao 2
        press_btn(3'b001);                          // INC_POSITION: 1 -> 2
        check("Posicao = 2 (estado S2)",
              dut.estado_atual == ST_S2);
        check("hex[4] exibe '3' (7'b0000110)",
              hex[4] == 7'b0000110);

        // Posicao 2: colocar digito 1
        press_btn(3'b010);                          // 0 -> 1
        check("Pos2: digito[2] = 1",
              dut.digitos[2] == 4'd1);

        // Avancar para posicao 3 (ultima)
        press_btn(3'b001);                          // INC_POSITION: 2 -> 3
        check("Posicao = 3 (estado S3)",
              dut.estado_atual == ST_S3);
        check("hex[4] exibe '4' (7'b1001100)",
              hex[4] == 7'b1001100);

        // Posicao 3: colocar digito 8
        press_btn(3'b010); press_btn(3'b010);
        press_btn(3'b010); press_btn(3'b010);
        press_btn(3'b010); press_btn(3'b010);
        press_btn(3'b010); press_btn(3'b010);       // 0 -> 1 -> ... -> 8
        check("Pos3: digito[3] = 8",
              dut.digitos[3] == 4'd8);

        // INC_POSITION na posicao 3 -> confere senha -> DESBLOQUEADO
        press_btn(3'b001);
        check("LEDs verdes acesos: senha CORRETA!",
              leds_verdes == 9'h1FF);
        check("LEDs vermelhos apagados",
              leds_vermelhos == 18'h00000);

        // Pular a espera do estado DESBLOQUEADO
        skip_led_wait();
        check("Sistema reiniciou apos LEDs verdes (digitos = 0)",
              todos_digitos == 16'h0000);

        // =============================================================
        // TESTE 7: Senha errada - sequencia 0-0-0-0
        // =============================================================
        $display("\n[Teste 7] Senha errada: 0-0-0-0");
        do_reset();

        // Avanca posicoes sem alterar digitos (todos permanecem 0)
        press_btn(3'b001); // pos 0 -> 1
        press_btn(3'b001); // pos 1 -> 2
        press_btn(3'b001); // pos 2 -> 3
        press_btn(3'b001); // pos 3 -> confere senha -> SENHA_ERRADA

        check("LEDs vermelhos acesos: senha ERRADA!",
              leds_vermelhos == 18'h3FFFF);
        check("LEDs verdes apagados",
              leds_verdes == 9'h000);

        // Pular a espera do estado SENHA_ERRADA
        skip_led_wait();
        check("Sistema reiniciou apos LEDs vermelhos (digitos = 0)",
              todos_digitos == 16'h0000);

        // =============================================================
        // TESTE 8: Independencia das posicoes
        // =============================================================
        $display("\n[Teste 8] Independencia dos digitos por posicao");
        do_reset();

        // Digito 5 na posicao 0
        repeat(5) press_btn(3'b010);                // 0->1->2->3->4->5
        check("Digito[0] = 5",
              dut.digitos[0] == 4'd5);

        press_btn(3'b001);                          // INC_POSITION: 0 -> 1
        check("Digito[1] = 0 (nao foi alterado)",
              dut.digitos[1] == 4'd0);

        // Digito 7 na posicao 1 (sem afetar posicao 0)
        repeat(7) press_btn(3'b010);                // 0->1->...->7
        check("Digito[1] = 7",
              dut.digitos[1] == 4'd7);
        check("Digito[0] = 5 (inalterado apos editar posicao 1)",
              dut.digitos[0] == 4'd5);
        check("Digito[2] = 0 (nao foi alterado)",
              dut.digitos[2] == 4'd0);

        // =============================================================
        // TESTE 9: Verificar que o cofre permanece em S0
        //          quando nenhum botao e pressionado
        // =============================================================
        $display("\n[Teste 9] Sem botao: estado estavel em S0");
        do_reset();

        repeat(10) @(posedge clk); // 10 ciclos sem pressionar nada
        check("Digitos inalterados sem botao pressionado",
              todos_digitos == 16'h0000);
        check("Posicao inalterada sem botao pressionado",
              dut.estado_atual == ST_S0);
        check("Sem LEDs vermelhos",  leds_vermelhos == 18'h00000);
        check("Sem LEDs verdes",     leds_verdes    == 9'h000);

        // =============================================================
        // Resultado final
        // =============================================================
        $display("\n================================================");
        $display("   RESULTADO FINAL: %0d / %0d testes passaram",
                 pass_cnt, test_num);
        if (fail_cnt == 0)
            $display("   TODOS OS TESTES PASSARAM!");
        else
            $display("   %0d TESTE(S) FALHARAM!", fail_cnt);
        $display("================================================");

        $stop;
    end

endmodule
