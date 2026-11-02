# SOUL / SWAP 0.8.0-test.4 — latência dos controles

Atualização do PvP local/LAN de DELTARUNE.

- Controles contínuos antigos deixam de ficar na fila. No teste com 13 pacotes acumulados, uma inversão de direção passou de 13 para 1 tick do anfitrião (433 para 33 ms a 30 FPS).
- Cliques, solturas, confirmações, evasão, roda e pausa continuam sendo consumidos em ordem, uma vez.
- Ping dedicado de ida e volta, independente do envio de estados; respostas antigas ou duplicadas são ignoradas.
- **Ambos devem atualizar:** protocolo LAN 2, incompatível com test.3 e anteriores.

- FPS locais, ping de ida e volta e taxa de estados de rede visíveis na tela, nos dois PCs.
- Janela de estados em trânsito ampliada de 2 para 8, ainda limitada para impedir acúmulo indefinido.
- Teste simulado com 100 ms de ida e volta: taxa recebida passou de 20 para 30 estados/s. Isso corrige um gargalo de rede; não comprova a causa de FPS baixo no computador do convidado.

- Música alterada para **THE WORLD REVOLVING**, do Capítulo 1.
- Instalador e build usam `mus/joker.ogg` da instalação própria do jogador, com conferência de SHA-256 no instalador.
- Gameplay continua na versão **0.8.0**; protocolo LAN passa para **2**.

- Conexão para dois jogadores por IPv4 + porta TCP (padrão 6510).
- Dez ataques e dois slots por jogador, com papéis alternados.
- Instalador Windows que usa o jogo instalado, baixa a ferramenta oficial e confere compatibilidade.
- Tutorial, README em português, solução de problemas e modelo de relato.

**Instalar:** baixe `SOUL-SWAP-0.8.0-test.4.zip`, extraia fora da pasta do jogo e abra `Install.cmd`. Depois abra `Start_LAN.cmd` ou `Start_Local_PvP.cmd`.

**Atualizar da test.1:** feche o jogo, extraia esta release em uma pasta nova e execute `Install.cmd`. Se substituir os arquivos do pacote na mesma pasta, execute `Install.cmd -Reinstall` para aplicar a nova música.

**Requisitos:** Windows 10/11 x64, DELTARUNE Steam na build compatível descrita no README, aproximadamente 1 GB livre e internet na primeira instalação. Não exige Python/Node/Git para jogar.

**Limites do teste:** a LAN foi verificada com dois runners reais no mesmo PC; o objetivo desta pré-release é coletar testes entre PCs físicos. O cliente não faz predição/interpolação. Os dois jogadores devem usar esta mesma release.
