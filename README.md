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

Cada dígito é limitado ao intervalo de 0 a 9 por meio de wrap-around explícito: ao chegar no 9 e seguir para a direita, volta para o 0; ao chegar no 0 e seguir para a esquerda, vai para o 9.
