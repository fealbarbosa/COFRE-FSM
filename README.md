# SAFECRACK PRO - SISTEMAS DIGITAIS 2026.2
## O Safecrack Pro é um sistema de simulação de cofre FSM descrito, neste projeto, por meio da linguagem de descrição de hardware (HDL) SystemVerilog, feito para ser visualizado e interagido com em uma máquina FPGA. O modelo utilizado nesta disciplina é a DE2-115.

### 1. Implementação dos requisitos

Este projeto prevê os seguintes requisitos para sua implementação:

- Senha de quatro dígitos, com apenas dígitos de 0 a 9 permitidos em cada índice.
- Os números devem ser exibidos em quatro displays de 7 segmentos (HEX3 – HEX0), com HEX3 correspondendo ao primeiro dígito e HEX0 ao quarto dígito.
- O sistema deve permitir que o usuário altere apenas um número de cada vez e exibe o dígito ativo por meio do display HEX4.
- Ao iniciar o sistema ou após um reset, o dígito ativo é igual a "1" e todos os valores de HEX3 a HEX0 mostram "0".
- Os quatro push buttons da placa (KEY[3] — KEY[0]) devem ser implementados no sistema de acordo com as orientações presentes no [website de orientações do projeto da disciplina](https://victormedeiros.notion.site/sd-projects-specs).

### 1.1 Senha e limites

A senha é 3518.

Ela é definida como parâmetro do módulo cofre:

```localparam logic [3:0] senha_cofre [0:3] = '{4'b0011, 4'b0101, 4'b0001, 4'b1000}; // 3, 5, 1, 8```

- Cada dígito é limitado ao intervalo de 0 a 9 por meio de wrap-around explícito: ao chegar no 9 e seguir para a direita, volta para o 0; ao chegar no 0 e seguir para a esquerda, vai para o 9.
- Cada dígito usa 4 bits, mas os valores 10 a 15 nunca são gerados. Se algum aparecesse, o decodificador mostraria -.
- A senha só é aceita se os quatro dígitos forem iguais aos da senha, na mesma ordem.
- Não há limite de tentativas: após cada resultado o sistema volta ao início e aceita uma nova senha.
- Tempo de feedback: 5 s (senha correta) e 3 s (senha incorreta), com clock de 50 MHz.

### 1.2 Uso dos botões

| Botão | Função | 
|---|---|---|
| KEY[3] |  Seta para a esquerda: decrementa o dígito ativo   | 
| KEY[2] |  Seta para a direita: incrementa o dígito ativo   | 
| KEY[1] | Confirmação: fixa o dígito ativo e avança para o seguinte. No quarto dígito, encerra a entrada e verifica a senha | 
| KEY[0] |  Reset: volta ao estado inicial (primeiro dígito ativo, displays em 0, LEDs apagados)  | 

- A navegação é sempre para frente: não há retorno a um dígito já confirmado. Para recomeçar, usa-se o reset (KEY[0]).

### 1.3 Displays de 7 segmentos e dígito ativo

- Os quatro dígitos da senha ficam guardados no vetor digitos[]. Cada um é enviado a um decodificador (bcd_to_7segment_anodo) que transforma o número (0 a 9) nos sinais que acendem os segmentos do display. Como os displays da DE2-115 são de ânodo comum, um segmento acende quando o sinal é 0. Se o decodificador receber um valor fora de 0 a 9, ele mostra um hífen (-).

- O dígito ativo é definido pelo estado da FSM, cada um dos estados S0 a S3 corresponde a um dígito. Em cada estado, só o dígito daquele estado muda quando KEY[2] ou KEY[3] é pressionado; os demais ficam como estão. Ao confirmar com KEY[1], a FSM passa para o estado seguinte e, com isso, para o próximo dígito.

### 1.4 Verificação e feedback

Após a confirmação do quarto dígito (KEY[1] em S3), o sistema compara os dígitos inseridos com senha_cofre.

+-----------------+--------------+---------------------------------------------+---------+--+
|    Resultado    |    Estado    |                   Feedback                  | Duração |  |
+-----------------+--------------+---------------------------------------------+---------+--+
| Senha Correta   | DESBLOQUEADO | Todos os LEDs verdes (LEDG[8:0]) acesos     | 5s      |  |
+-----------------+--------------+---------------------------------------------+---------+--+
| Senha Incorreta | SENHA_ERRADA | Todos os LEDs vermelhos (LEDR[17:0]) acesos | 3s      |  |
+-----------------+--------------+---------------------------------------------+---------+--+

Ao término do intervalo, o sistema retorna automaticamente a S0, os displays voltam a exibir 0 e o primeiro dígito torna-se novamente o dígito ativo.

### 2. Diagrama de Estados


### 3. Simulação e diagramas de tempo (waveforms)


### 4. Known issues

- Depois de confirmar um dígito (KEY[1]), não é possível voltar a ele para corrigir o valor. Para refazer a entrada, é preciso usar o reset (KEY[0]) e começar do primeiro dígito.
- Se dois botões forem pressionados no mesmo ciclo, KEY2 tem prioridade sobre KEY3, e KEY1 não confirma.
- No caso em que apertar o reset ao mesmo tempo que outra KEY, dará erro.

