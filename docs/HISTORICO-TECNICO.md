# Histórico técnico — SOUL / SWAP até v0.8.0

Registro das versões e verificações anteriores. Para instalar e jogar a versão de testes, veja o [README atual](../README.md).

Abra **`Start_Local_PvP.cmd`** para o modo local ou **`Start_LAN.cmd`** para a conexao de rede. Ambos usam `play-v0.8.0/`. O lobby local tambem tem o botao **JOGAR EM LAN**.

## LAN: IPv4 + porta — v0.8.0

1. Os dois PCs precisam da **mesma versao 0.8.0**, na mesma rede local, com os arquivos completos da pasta `play-v0.8.0` (`data.win`, executavel, banco de audio, musica e `options.ini`). O launcher `Start_LAN.cmd` fica ao lado dessa pasta. Cada instalacao deve partir de uma copia propria do jogo.
2. **Anfitriao/P1:** abra `Start_LAN.cmd`, escolha a porta (padrao **6510 TCP**) e clique **HOSPEDAR**. O campo IPv4 nao e usado ao hospedar; o servidor escuta nas interfaces locais.
3. O launcher mostra os IPv4 do PC. Passe ao outro jogador o endereco da interface Ethernet/Wi-Fi usada na rede, por exemplo **192.168.1.10**, e a porta escolhida. Tambem pode consultar `ipconfig` no terminal.
4. **Convidado/P2:** clique no campo IPv4, apague o valor anterior com Backspace e digite o IPv4 de P1; informe a mesma porta e clique **CONECTAR**. `127.0.0.1` serve apenas para duas instancias no mesmo PC, nao para outro computador.
5. Se o Windows perguntar, permita o executavel na **rede privada**. A porta TCP escolhida precisa estar liberada para entrada no PC anfitriao. Esta versao nao faz descoberta automatica nem configuracao de roteador.
6. No lobby, cada jogador confirma **no seu proprio PC**: o atacante clica no botao de mouse; o defensor aperta Enter. Apenas o atacante escolhe os ataques. Durante o turno, ele usa o mouse e o outro usa WASD/setas, foco e Q. Na troca de papel, cada um continua no seu PC e passa a usar o controle indicado na tela.

**Pausa e saida:** P/Esc ou PAUSA interrompe a partida para os dois. Perder foco ou abrir AJUDA tambem congela a simulacao; ambos precisam voltar ao jogo e fechar AJUDA. Uma pausa manual e liberada pelo botao CONTINUAR. No menu de pausa LAN, DESCONECTAR encerra a sessao; os dois podem hospedar/conectar novamente. Sair durante uma partida nao retoma o turno antigo: a reconexao abre um novo lobby.

**Conexao:** mostra erro de IPv4/porta, porta ocupada, versao diferente, falha de conexao e desconexao. A conexao inicial tem prazo de 7s; uma sessao sem dados por 0,5s congela e por 5s e encerrada. Esperar um convidado antes de qualquer conexao nao tem limite. Um terceiro jogador e rejeitado.

### Implementacao e verificacao LAN

- Servidor autoritativo: apenas P1 simula dano, projeteis, energia e fases, independentemente de quem esta atacando. P2 envia controles, nunca HP ou posicoes de combate.
- TCP nativo GameMaker com framing (`network_connect_async` / `network_send_packet`), handshake com protocolo/versao, sequencias, fila limitada, isolamento de controles por papel e descarte de comandos de fases antigas.
- Snapshots a ate 30Hz, listas compactas de projeteis, campos de estado permitidos explicitamente e no maximo dois snapshots aguardando confirmacao. O cliente apresenta o estado recebido, sem predicao/interpolacao; a resposta do convidado inclui a latencia de rede. O indicador em ms mede o tempo ate confirmacao de input, incluindo o agendamento dos frames.
- Perda de foco, ajuda e pausa nao interrompem heartbeat/snapshots. Sockets e buffer proprio sao liberados ao sair. O buffer de evento async e lido somente durante o evento e nao e retido.
- `gml/network.gml`: conexao, protocolo, fila de input, estado e menus. `gml/network-event.gml`: evento async Other 68. `gml/end-step.gml`: publica estado apos os retornos do Step. `gml/cleanup.gml`: libera recursos.
- Testes simulados de transporte integram dois controladores e verificam handshake, papeis, replicas, mira, pausas, timeout, filas e invalidacao de pacotes. `tests/lan-smoke.ps1` inicia **dois executaveis reais** por loopback, usa input sintetico apenas com `--lan-test`, verifica combate/troca de papeis/dano, compara assinaturas do estado e fecha o host para testar desconexao.

Comandos opcionais: `DELTARUNE_Local_PvP.exe --lan`, `--lan-host 6510`, `--lan-join 192.168.1.10 6510`. Execute dentro da pasta do build. Nao use `--lan-test` para jogar: e exclusivo do teste automatizado.

O teste de loopback valida o runner e o transporte real em um PC. Conexao entre dois PCs fisicos, firewall da rede e sensacao de controle sob latencia precisam ser verificados na sua LAN.

**Resultado da v0.8.0:** 88 testes de gameplay/UI/rede e dois de configuracao passaram; build compilado e reaberto com os seis eventos. No teste real por TCP/127.0.0.1, os dois processos chegaram a 626 ticks de combate, 100 de dano acumulado e 747 snapshots verificados por assinatura de fase/HP/energia/posicao/contagens, com os dois papeis exercitados. Fechar o anfitriao devolveu o convidado ao menu de conexao. Relatorio: `build/lan-smoke.json`. Lobby e formulario LAN foram inspecionados no runner em 640x480; capturas em `build/ui-0.8.0-*.png`.

## Ataques refeitos — v0.7.0

| Ataque | Esquerdo | Direito |
|---|---|---|
| Rajada | Cinco tiros em leques alternados, a cada 0,4s | Emissor extra com leques de tres tiros |
| Cometa | Tres linhas de cometas; guia limitada aos primeiros 0,8s | Mina com duas ondas de 12 tiros, alternadas em 15 graus |
| Muralha | Parede densa, com passagem na linha do cursor | Arraste: duas paredes de lados opostos; a segunda desloca a passagem e avisa novamente |
| Pulso | Dois aneis no cursor; a abertura de 60 graus muda entre ondas | Par de aneis atrasado no ponto escolhido |
| Ricochete | Leque de tres tiros com dois rebotes cada | Refletor horizontal/vertical por arrasto |
| Orbita | Oito tiros formam um circulo ao redor da mira e saem em sequencia, cobrindo os flancos | Inverte o giro das formacoes |
| Pinca | Leques de tres tiros de bordas opostas, escalonados | Cruzamento horizontal seguido do vertical |
| Costura | Desenhe ate 260 pixels: seis tiros percorrem os dois sentidos e espinhos saem pelas laterais | Inverte qual ponta dispara primeiro |
| Bumerangue | Solte para lancar tres laminas; carregar por cerca de 0,67s libera cinco | Trava uma nova passagem pelo cursor e antecipa a volta |
| Jardim | Plante ate tres sementes; viajam mais rapido e amadurecem em 0,6s | As verdes soltam duas ondas de petalas; a primeira tambem tem leque dirigido |

**Bumerangue:** mesmo um clique curto passa alem da mira inicial. Cada lamina vai ate seu alcance/borda, para e mostra a rota de volta por 0,4s. Ela passa pelo cursor capturado naquele momento (com espacamento entre laminas) e depois retorna a origem. Mover o mouse depois do aviso nao muda aquela rota. Use o direito para escolher o momento e a direcao do contra-ataque. A carga maxima leva um segundo; a vida e limitada a 320 ticks e nunca e renovada.

**Costura/Jardim:** avisos direcionais mostram os espinhos e o florescimento. Os tiros ja lancados continuam com sua identidade quando voce troca de slot. A ajuda e as descricoes de esquerdo/direito na selecao foram atualizadas.

**Correcoes de estados:** rebater em um refletor nao consome o segundo rebote na mesma passagem. Trocar de um ataque de 10 para outro de 20 de energia inicia recuperacao se necessario, mesmo segurando o esquerdo. O limite de projeteis nao permite alterar por engano o ultimo tiro existente ao tentar criar uma costura ou bumerangue.

### Verificacao da revisao

Resultado final: **75 testes de gameplay/interface + 2 de configuracao passaram**, arquivo compilado e reaberto. A bateria de stress atingiu 161 projeteis (limite 256); as 45 duplas atingiram 129. Na comparacao deterministica, ocupacao por projeteis ativos cresceu em todos os dez ataques; Bumerangue: 5,91x. Esse numero nao significa 5,91x de dificuldade humana.

Capturas do runner dos dez ataques, menu e ajuda foram inspecionadas em 640x480. O teste detectou e levou a corrigir inicializacao de `fire_released` nos previews criativos; tambem foi corrigido o desenho de projeteis fora da arena sobre o HUD. Pulso expandido, aviso/retorno do Bumerangue e Costura foram reconferidos; a ultima compilacao foi inspecionada com Pulso, Bumerangue e Costura em 1280x960, sem dialogo de erro. Capturas em `build/ui-0.7.0-*.png`. A verificacao visual usa estados congelados, nao uma partida interativa completa.

Os testes exercitam os dez ataques, as 45 duplas, avisos sem dano, trajetorias de ida/volta, aberturas, expiracao, energia, pausas, selecao, tutorial e limites da interface. A comparacao com o controlador decompilado da v0.6.2 usa o mesmo input de mouse e mede ocupacao de 528 pontos da arena por projeteis ativos durante turnos de 15s. Relatorio: `build/pressure-comparison.json`. Isso mede cobertura/persistencia; o equilibrio entre jogadores exige partida real.

Para capturas dos ataques reais em estados reproduziveis, passe `-Scenarios attack0,attack1,...,attack9` ao script `tests/ui-review.ps1` em uma chamada PowerShell com array. Os previews executam os helpers e 40 ticks de simulacao antes de congelar. O executavel normal nao usa esse modo.

Integracao: GameMaker/GML do runner instalado, fixado pelos hashes abaixo; `patch.csx` compila os eventos do controlador. A simulacao usa 30 ticks/s e input por bordas de press/release em `step.gml`; `clear_attacks` encerra os objetos de cada turno. `draw.gml` apenas apresenta estado. O teste JS e uma traducao de sintaxe com APIs simuladas; `build.py` recompila e reabre o arquivo no toolchain real.

## Tutorial v0.6.2

O botao **AJUDA**, no topo, abre tres paginas: selecionar ataques, jogar como atacante e jogar como defensor. A partida e o tempo de escolha param durante a leitura. Clique em ANTERIOR/PROXIMA para navegar e ENTENDI/FECHAR ou Esc para voltar. Se abriu na pausa, volta para a pausa.

**Selecao:** clique no slot 1 ou 2, depois no cartao do ataque; PAGINA mostra os restantes. Confira os dois nomes nos slots e clique CONFIRMAR. Duplicatas trocam de slot. O painel inferior mostra separadamente o gesto do esquerdo e do direito de cada ataque.

**Mouse:** mire dentro da arena; esquerdo usa o principal, direito o especial e a roda alterna os dois ataques. Costura exige desenhar e soltar; Bumerangue exige carregar e soltar; Muralha/Refletor exigem arrastar e soltar o direito. Jardim exige sementes verdes antes do direito.

**Teclado:** WASD/setas movem o SOUL; Shift/espaco reduzem velocidade; Q + direcao ativa uma evasao por turno, sem invulnerabilidade. Ao trocar os papeis, passem o mouse e confirmem novamente.

## Revisao de interface e estados v0.6.1

- Lobby com cartoes separados de atacante/defensor; selecao com slots, destaque do ataque equipado, hover e painel de descricao. Molduras, fontes, personagens e icones continuam sendo assets originais.
- Uma unica faixa de status acima da arena: prioridade para liberar clique, troca, gesto ativo e aviso do especial. Nada de porcentagens, dano ou mensagens flutuando sobre o SOUL.
- Energia e especial em barras fixas; dano/esquiva/evasao em uma linha propria no rodape. O SOUL e desenhado acima das particulas de impacto. Pausa tem fundo opaco.
- Textos respeitam largura medida com a fonte real, com reticencias se necessario. A resolucao logica continua 640x480.
- Selecionar outro slot atualiza pagina, ataque e descricao juntos. Troca limpa aviso obsoleto; pausar cancela evasao em andamento. Gestos de outro ataque nao aparecem na faixa de status.
- 58 testes de gameplay/UI e dois testes de configuracao. Os testes de interface verificam colisoes entre caixas de texto, limites da tela e ausencia de texto na arena durante combate. As metricas simuladas sao complementadas por capturas do runner.

`tests/ui-review.ps1` abre e fecha apenas processos de preview criados por ele, capturando lobby, selecao, combate com efeitos simultaneos, combinacao de semente/carga e pausa. `-Native` usa 640x480; sem a opcao usa o tamanho inicial normal. O modo e ativado exclusivamente pelo argumento `--pvp-ui-check` e congela estados artificiais de teste. A partida normal nao usa esse modo. Capturas ficam em `build/ui-0.6.1-*.png`. Teste visual de estados nao substitui uma partida completa com dois jogadores.

Verificacao desta revisao: foram inspecionadas capturas reais do runner do lobby, selecao, combate, carga com sementes e pausa a 1280x960; apos o ajuste final das particulas, selecao/combate/carga foram novamente inspecionados em 640x480. Nenhuma sobreposicao de texto foi observada nesses estados. Capturas nativas terminam em `-native.png`. O teste nao comprova que todos os bugs de uma partida interativa foram eliminados.

## Pacote criativo v0.6.0

Agora sao **10 ataques**. A selecao tem duas paginas: clique em PAGINA para encontrar Costura, Bumerangue e Jardim, ou use a roda para percorrer todos os ataques do slot. Mantem dois slots, troca pela roda durante combate, evasao Q e turnos de 15 segundos.

- **Costura:** segure o esquerdo e desenhe dentro da arena, depois solte. Limite de 160 pixels/32 pontos; tres diamantes percorrem a linha apos aviso de 0,8 segundo, em sequencia. O desenho nao causa dano. Direito alterna o sentido da proxima costura. Um clique sem trajeto nao gasta energia. Soltar fora cancela.
- **Bumerangue:** segure o esquerdo para carregar alcance (ate 1,5 segundo) e solte para lancar. Ao atingir o alcance ou a borda ele para, avisa por 0,4 segundo e retorna ao ponto de origem. Direito antecipa uma unica volta dos bumerangues ativos. Nao renova sua vida util; retorna e desaparece. Durante a carga aparece a previa de alcance; antes da volta aparece a linha de retorno.
- **Jardim:** esquerdo planta ate tres sementes, que viajam da borda ate o cursor sem causar dano. Amadurecem apos chegar e ficam verdes, com seta da direcao do futuro disparo. Direito ativa as maduras: aviso de 0,8 segundo e florescimento sequencial com intervalo de 0,4 segundo, cada uma lancando um leque de tres tiros. Sementes expiram e sao removidas ao terminar o turno. Plantio fica indisponivel nos ultimos tres segundos.

Cada disparo principal desses tres ataques custa 20 de energia. Especiais compartilham recarga; direito sem bumerangue ativo ou semente madura informa o motivo sem gastar recarga. Gestos incompletos sao cancelados ao pausar, perder foco, trocar ataque ou sair da arena; ataques ja lancados preservam seu comportamento. Assets sao todos originais reutilizados, com trajetorias e avisos desenhados por codigo.

Este pacote implementa Costura, Bumerangue e Jardim. Ima, Portais e Compasso permanecem propostas para uma proxima expansao. A montagem da dupla continua antes de cada turno; nao ha uma fase adicional de posicionamento gratuito.

Validacao v0.6.0: suite ampliada para 54 testes de gameplay, incluindo trajetos limitados, volta unica, avisos inofensivos, tres sementes, maturacao, detonacao escalonada e cancelamento de gestos; mais dois testes de configuracao. Testes simulados nao comprovam audio, visual de combate ou equilibrio com dois jogadores.

## Correcao v0.5.2: cursor visivel

Ativa explicitamente o cursor nativo ao iniciar e alternar tela cheia. A seta original `spr_custommenu_arrow` tambem e desenhada por ultimo, sobre menus, pausa e arena, nas coordenadas GUI reais do mouse, com contorno escuro para contraste. Nao fica limitada a area de combate. Build e 46 testes de gameplay mais dois de configuracao passaram; a confirmacao visual no runner e separada dos testes simulados.

## Correcao v0.5.1: clique direito

O bloqueio de confirmacao agora afeta somente o esquerdo. Um clique direito novo funciona mesmo mantendo esquerdo ou Enter pressionados depois de uma transicao. Um direito ja segurado antes da transicao continua sem ativar automaticamente. Mensagens informam recarga, cursor fora da arena, troca de ataque, fim de turno e arrastar/soltar. F3 mostra `DIR`, contador de cliques direitos recebidos, para diagnostico no runner.

44 testes de gameplay e dois testes de configuracao passaram; incluem clique direito com esquerdo segurado, arrasto independente e botoes mantidos entre fases. A confirmacao com o mouse real ainda depende do teste na nova janela.

## Novidades da v0.5.0

Sete ataques, dois slots por jogador e evasao defensiva. Antes de cada turno, clique no slot 1 ou 2 e depois no cartao do ataque. A roda percorre os ataques do slot selecionado; duplicatas sao trocadas de slot automaticamente. A dupla fica guardada para o proximo turno daquele jogador, mas pode ser alterada. A escolha dura ate dez segundos.

Em combate, a roda alterna os dois slots com aviso de 0,6 segundo. Energia, recuperacao e recargas sao compartilhadas; tiros e especiais ja existentes mantem seu tipo original. Arrastos pendentes sao cancelados pela troca.

**Q + direcao** ativa evasao uma vez por turno: seis ticks de movimento a oito pixels/tick, ate 48 pixels. Nao concede invulnerabilidade nem atravessa projeteis: a colisao considera o trajeto inteiro. Shift/espaco continuam sendo foco.

O resumo de tres segundos mostra dano, esquivas por pouco e ataque que mais acertou. A confirmacao de passagem do mouse continua sem limite de tempo.

### Quatro novos ataques

- **Pulso:** anel incompleto emitido da borda, com abertura de 90 graus orientada pela mira. Direito coloca outro pulso com aviso de um segundo; a orientacao da abertura fica fixada pela posicao escolhida em relacao ao centro da arena e aparece na previa.
- **Ricochete:** um tiro rebate uma unica vez numa parede ou refletor. Arraste com o direito e solte dentro da arena para colocar um refletor horizontal/vertical de 80 pixels; avisa por um segundo e dura tres segundos. A linha tenue mostra a trajetoria e o primeiro rebote previsto, incluindo o refletor em preparo. A vida do projetil nao e renovada ao rebater.
- **Orbita:** tres projeteis orbitam um centro fixo perto da borda por um segundo, sem causar dano, e depois miram o cursor e saem com novo aviso. Direito inverte o giro dos projeteis em formacao e dos proximos. Os projeteis nao seguem o SOUL nem o mouse durante a formacao.
- **Pinca:** dois tiros partem de bordas opostas em direcao ao cursor. Direito fixa um cruzamento; depois de um aviso visual de um segundo, quatro leques convergem das bordas para o ponto marcado.

Todos reutilizam os sprites/fontes/sons originais presentes no manifesto; linhas de trajetoria e avisos sao indicadores desenhados por codigo.

## Melhorias da v0.4.0

- Segurar botoes nas transicoes nao congela mais o relogio ou a movimentacao do defensor; apenas os ataques aguardam a liberacao dos botoes.
- Energia esgotada entra em recuperacao automatica ate 30%, mesmo segurando o disparo. Cadencia principal passa de 0,6 para 0,5 segundo.
- Barras visuais de energia e recarga especial, efeito curto no emissor, particulas com o diamante original e numero de dano.
- Esquivas por pouco: cada projetil concede no maximo um registro, com som original `snd_graze` e destaque breve. Nao altera HP nem aumenta dano. Turnos sem dano recebem destaque de defesa perfeita; resultados mostram as estatisticas.
- Atualizacao dos projeteis compacta o array existente em vez de criar um novo a cada tick. Limite explicito de 256 projeteis.
- Perda de foco prevalece sobre cliques de menu. F3 mostra quantidade de projeteis e tempo de CPU da atualizacao dos projeteis em microssegundos; nao representa tempo total de frame/GPU.
- Build executa testes antes de compilar e exige arquivo/relatorio novos, impedindo que uma falha do CLI reaproveite silenciosamente uma compilacao anterior.

## Mouse ataca, teclado desvia

Os jogadores alternam os papeis, passando fisicamente o mouse a cada turno. Kris/P1 inicia atacando; a abertura alterna nas revanches. Antes de cada turno, a tela identifica quem recebe cada dispositivo e espera os dois confirmarem, sem limite de tempo.

| Acao | Controle |
|---|---|
| Atacante pronto | Clique no botao MOUSE |
| Defensor pronto | Enter |
| Selecionar padrao | Roda do mouse ou clique no cartao |
| Confirmar padrao | Clique em CONFIRMAR ATAQUE |
| Mirar | Mouse dentro da arena |
| Disparar | Segure o botao esquerdo |
| Estrategia | Botao direito; na Muralha, arraste e solte |
| Defender | WASD ou setas |
| Movimento preciso | Segure Shift ou espaco |
| Evasao, uma por turno | Q enquanto se move |
| Trocar ataque em combate | Roda do mouse |
| Pausa, som, tela cheia | Botoes clicaveis no topo; atalhos P/Esc, M, F4 |

O atacante opera toda sua interface com o mouse. O teclado movimenta apenas o defensor atual. Os controles antigos F/K e a atribuicao de gamepads nao fazem parte deste modo.

## Padroes anteriores (v0.3–v0.6; substituidos pela tabela v0.7.0)

- **Rajada:** leque de tres tiros da borda mais proxima em direcao ao cursor. Botao direito posiciona um segundo emissor na borda, que acompanha a mira ao disparar por tres segundos.
- **Cometa:** um tiro curva em direcao ao cursor por um segundo, limitado a tres graus por tick; depois segue reto. Botao direito coloca uma mina visivel, com um segundo de aviso antes de soltar oito projeteis radiais.
- **Muralha:** leque mais aberto no disparo principal. Arraste com o direito para escolher orientacao horizontal/vertical e solte dentro da arena para confirmar. O inicio do arrasto determina a abertura segura e o lado de origem. A previa mostra as mesmas posicoes dos projeteis. Soltar fora cancela.

Ataques estrategicos colocados na arena avisam por um segundo antes de ativar e recarregam em quatro segundos. A inversao da Orbita e imediata, durante a formacao inofensiva. Especiais nao podem ser usados nos ultimos dois segundos do turno. Novos projeteis ainda tem seu breve aviso antes de se mover e causar dano. Cometa curva, Ricochete rebate uma vez e Orbita gira antes de lancar; os demais seguem trajetorias fixas.

## Ritmo e regras

- Ataques de **15 segundos** a 30 ticks/s, escolha de ate dez segundos e contagem inicial de 1,2 segundo.
- 100 HP por jogador; 10 de dano por acerto, com 0,8 segundo de invulnerabilidade.
- Energia de 100; Muralha, Pulso, Costura, Bumerangue e Jardim custam 20; os demais custam 10 por disparo. Soltar o esquerdo recupera 27 por segundo. Energia insuficiente recupera automaticamente ate 30, inclusive apos trocar de slot. Os especiais usam recarga compartilhada de quatro segundos.
- Velocidade-base de 3,4 pixels/tick, com valores proprios por ataque: paredes 3,2, aneis 2,9, petalas 2,8 e laminas do Bumerangue 4,5 na ida / 5,2 na volta. Movimento normal do defensor continua 4; foco 2; evasao 8. Dano e invulnerabilidade continuam iguais.
- KO termina imediatamente; apos 12 turnos completos, vence quem tiver mais HP. Empate se HP iguais.
- Pausa interrompe temporizadores, movimento e ataques. Perder foco pausa automaticamente. Cliques de confirmacao precisam ser soltos para habilitar novos ataques, sem congelar a simulacao apos retomar.

## Assets originais

Usa 17 sprites originais do arquivo instalado de Chapter 2: Kris/Susie animados, SOUL, projeteis, moldura, rotulo HP e seta. Fontes `fnt_main`/`fnt_mainbig`, sons de menu/acerto e `battle.ogg` tambem sao originais. Novas habilidades reutilizam esses sprites com escala, rotacao e cor. Barras, texto e indicador de hitbox sao desenhados por codigo.

`assets/manifest.json` registra a procedencia. A moldura usa o nine-slice nativo via `draw_sprite_stretched_ext`, preservando a correcao do erro de desenho da v0.2.0. O hitbox circular e as regras PvP sao proprios do mod, nao as mascaras de combate da campanha.

## Build e verificacao

```powershell
node tests/controller.test.cjs
python build.py --rebuild
```

O build usa UndertaleModCli 0.9.2.0 da pasta irma `deltarune-pvp-research/tools/utmt-0.9.2.0/`. Exige a instalacao local compativel:

- Chapter 2 SHA-256: `047c5ab003e3e017a709c02757e119c81e0327760169512110fd276b19241e68`.
- Runner SHA-256: `b882cc1879ad8f24c63fa6e4f47a8fef9a01065ee61ad6220beed9932b04e7ed`.

Compila os seis eventos do controlador (Create, Step, End Step, Draw GUI, Networking e Clean Up), reabre/decompila o arquivo resultante e confere os recursos exigidos. O round-trip sem alteracoes e identico ao original. A pasta de saida e versionada, mantendo builds anteriores. Manifesto e relatorios ficam em `build/`.

Os testes executam o GML real convertido para sintaxe JS com APIs simuladas. Incluem 36 turnos completos pseudoaleatorios (16.200 ticks), mais 45 duplas (20.250 ticks) e a comparacao de dez ataques em duas versoes (9.000 ticks). Mais dois testes Python verificam regras atuais e 11 configuracoes invalidas. Nao substituem teste do runner, mouse real, tela cheia, audio e balanceamento com dois jogadores.

Teste inicial no runner: v0.5.0 abriu e o lobby foi conferido em `build/runtime-v0.5.0.png`, sem dialogo de erro. A automacao de input foi interrompida porque a janela nao ficou em primeiro plano. Portanto, os novos ataques ainda precisam de verificacao visual em combate e teste com dois jogadores. `tests/runtime-smoke.ps1` permite repetir esse teste interativo com capturas por etapa; ele interrompe os inputs se outra janela ganhar foco.

Microbenchmark com 256 projeteis estacionarios/invulnerabilidade, cinco lotes de 1.000 atualizacoes: mediana de 0,219 ms antes para 0,159 ms depois (aproximadamente 28% menos tempo). Esse numero mede GML traduzido executado em Node, nao FPS do GameMaker. Registro: `build/performance-v0.4.0.json`.

## Isolamento

Boot exclusivo em `room_pvp_arena`, um controlador, zero inicializadores globais da campanha e identidade distinta. O codigo novo nao chama APIs de save/INI/arquivos da campanha; a API de audio le o `battle.ogg` local. HP e vitorias sao mantidos em memoria. Hashes do runner e arquivo originais sao reconferidos ao final do build; atividade de arquivos do runner nao foi monitorada.

As copias locais contem assets protegidos do jogo. Para distribuir o mod, forneca os scripts/patch e exija a instalacao propria do destinatario, em vez de distribuir executavel, arquivo do jogo ou banco de sons.
