# SOUL / SWAP — DELTARUNE PvP local e LAN

**Versão de testes: `0.8.0-test.4` · jogo: `0.8.0` · protocolo LAN: `2` · Windows 64 bits**

Mod não oficial para dois jogadores: um ataca com o mouse e o outro desvia com o teclado. Os papéis se alternam. Inclui dez ataques, seleção de dupla, tutorial no jogo e conexão LAN por **IPv4 + porta TCP**.

A música é **THE WORLD REVOLVING**, do Capítulo 1 (`mus/joker.ogg` da instalação original, copiada como `battle.ogg` no mod).

## O que você precisa

| Requisito | Detalhes |
|---|---|
| Sistema | Windows 10/11 de 64 bits, com Windows PowerShell 5.1 (incluído no Windows) |
| Jogo | Instalação própria e compatível de **DELTARUNE para Windows/Steam**, com `chapter2_windows` |
| Espaço | Reserve **1 GB livre** para download, compilação temporária e instalação |
| Internet | Na primeira instalação, para baixar a ferramenta oficial UndertaleModCli (~63 MB). Depois, o modo LAN funciona sem internet |
| Controles | Mouse e teclado; dois PCs na mesma rede para jogar por LAN |
| Versão | Os dois jogadores devem instalar o mesmo pacote |

**Para instalar e jogar, não precisa de Python, Node.js, Git, GameMaker nem .NET SDK.** A ferramenta de compilação é baixada automaticamente, em versão fixa, com conferência de SHA-256.

### Compatibilidade do jogo

Esta release aceita **uma build específica** de DELTARUNE, conferida automaticamente pelos arquivos. Outras atualizações, demo, versões de console/macOS/Linux e arquivos já modificados não estão validados. A instalação é interrompida se os hashes forem diferentes.

Os hashes e nomes dos quatro arquivos aceitos estão em [`release/compatibility.json`](release/compatibility.json). Não há opção para ignorar essa conferência.

## Instalação — passo a passo

1. Baixe **[SOUL-SWAP-0.8.0-test.4.zip](https://github.com/pedrohsahsa-art/soul-swap/releases/download/v0.8.0-test.4/SOUL-SWAP-0.8.0-test.4.zip)** na release do GitHub.
2. Use **Extrair tudo**. Coloque a pasta em um local onde você possa gravar arquivos, por exemplo `Documentos\SOUL-SWAP`. **Não execute de dentro do ZIP nem extraia dentro da pasta original de DELTARUNE.**
3. Abra **`Install.cmd`**. Não é necessário executar como administrador.
4. O instalador procura o jogo nas bibliotecas Steam. Se não encontrar, selecione a pasta **DELTARUNE**, que contém `DELTARUNE.exe`, `chapter2_windows` e `mus`.
5. Aguarde a mensagem **PRONTO**. Ele baixa a ferramenta, compila o mod e verifica o resultado antes de disponibilizá-lo.
6. Abra **`Start_Local_PvP.cmd`** para jogar no mesmo PC ou **`Start_LAN.cmd`** para jogar em rede.

A instalação cria `play-v0.8.0` **dentro da pasta do mod**. Os arquivos originais da Steam não são substituídos. Guarde a pasta inteira do mod para os atalhos continuarem funcionando.

**Se precisar indicar outra biblioteca Steam**, abra um terminal na pasta do mod e execute:

```bat
Install.cmd -GameDirectory "D:\SteamLibrary\steamapps\common\DELTARUNE"
```

Para apenas conferir compatibilidade: `Install.cmd -ValidateOnly`. Para reinstalar: `Install.cmd -Reinstall`. A reinstalação preserva a versão anterior em uma pasta `play-v0.8.0.previous-...` depois de preparar o novo build.

## Jogar por LAN

### P1 — hospedar

1. Abra `Start_LAN.cmd`. A janela de terminal mostra os IPv4 do computador.
2. Escolha uma porta; a padrão é **6510**. Clique **HOSPEDAR / P1**.
3. Envie ao outro jogador o IPv4 da interface Wi-Fi/Ethernet usada na rede, por exemplo `192.168.1.10`, e a porta.

### P2 — conectar

1. Abra `Start_LAN.cmd` no outro PC.
2. Clique no campo IPv4, apague o valor com Backspace e digite o **IPv4 de P1**.
3. Informe a mesma porta, por exemplo **6510**, e clique **CONECTAR / P2**.

**Importante:** `127.0.0.1` só serve para duas instâncias no mesmo computador. Para outro PC, use o endereço da rede local do anfitrião. Ambos devem estar na mesma LAN; redes de visitantes podem bloquear a comunicação entre dispositivos.

Se o Windows perguntar, permita o jogo na **rede privada**. O PC anfitrião precisa aceitar entrada na porta **TCP** escolhida. Não é necessário encaminhar portas do roteador para jogar dentro da mesma rede. Conexão pela internet e descoberta automática de salas não fazem parte desta versão.

### Dentro da partida

- O **atacante** confirma clicando em MOUSE PRONTO no próprio PC.
- O **defensor** confirma com **Enter** no próprio PC.
- Só o atacante seleciona os ataques. Clique no **slot 1 ou 2**, depois no ataque, e em **CONFIRMAR**. O botão PAGINA mostra os restantes.
- Quando o papel mudar, **cada um continua no seu computador**, usando mouse ou teclado conforme a tela indicar.
- P/Esc ou PAUSA pausa para ambos. Abrir AJUDA ou sair do foco também congela o jogo. Para continuar, ambos precisam voltar ao jogo e fechar AJUDA; se houve pausa manual, use CONTINUAR.
- Para sair da sala: PAUSA → DESCONECTAR. Uma nova conexão começa outra sessão.

## Controles

O topo mostra **FPS** locais (alvo: 30), **PING** de ida e volta em milissegundos e **REDE /s** (estados enviados pelo anfitrião ou recebidos pelo convidado). O ping usa uma mensagem própria, respondida no evento de rede, independente dos estados da partida. Ainda inclui o agendamento de eventos do GameMaker; não equivale ao ping ICMP do Windows. `--` significa sem medição. As taxas são atualizadas a cada segundo. FPS perto de 30 com REDE baixa indica atualizações de rede irregulares; FPS baixo indica que o próprio jogo está rodando devagar.

**Os dois PCs precisam atualizar para test.4 ou posterior compatível:** o protocolo LAN 2 recusa as releases anteriores. Controles contínuos acumulados são substituídos pelos mais recentes, preservando ações discretas em ordem. Não há predição no cliente: a distância e a latência real da conexão ainda afetam a resposta.

| Ação | Controle |
|---|---|
| Mirar / atacar | Mouse / botão esquerdo |
| Especial | Botão direito; alguns ataques exigem arrastar e soltar |
| Alternar entre os dois ataques | Roda do mouse |
| Desviar | WASD ou setas |
| Movimento preciso | Shift ou espaço |
| Evasão, uma por turno | Q + direção; **não** dá invulnerabilidade |
| Tutorial | Botão AJUDA |
| Pausa / som / tela | Botões no topo; P/Esc, M e F4 |

**Costura:** segure, desenhe e solte. **Bumerangue:** carregue e solte; direito traz a volta pelo cursor. **Jardim:** plante e espere as sementes ficarem verdes antes de usar o direito. As descrições ESQ/DIR na seleção explicam cada ataque.

No modo local, os dois jogam no mesmo PC e passam o mouse quando os papéis mudam. Os turnos de ataque duram 15 segundos.

## Problemas comuns

| Problema | Como resolver |
|---|---|
| “Jogo incompatível” | Confira se escolheu a pasta correta e se ela tem outros mods. Envie o hash mostrado no log ao autor. Uma atualização do jogo pode exigir outra release do mod |
| Não encontrou o jogo | Steam → DELTARUNE → Gerenciar → Explorar arquivos locais; use essa pasta em `-GameDirectory` |
| Falha no download | Confira internet/proxy e tente novamente. Há instalação offline da ferramenta descrita em [DESENVOLVIMENTO.md](docs/DESENVOLVIMENTO.md) |
| “Já está instalado” | Abra um dos `Start_*.cmd`; para refazer, feche o jogo e use `Install.cmd -Reinstall` |
| Porta ocupada | Escolha outra, por exemplo 6511, **nos dois PCs** |
| Não conecta / tempo esgotado | Confira IPv4, porta, rede privada, firewall e isolamento de dispositivos do roteador |
| “Versões diferentes” | Instale o mesmo ZIP nos dois PCs |
| Partida pausada sozinha | Ambos devem manter a janela em foco e fechar AJUDA |
| Teste de duas janelas no mesmo PC pausa | A perda de foco pausa por projeto. Para jogar normalmente por LAN, use dois PCs |

Logs de instalação ficam em **`.logs`**. Veja [COMO-REPORTAR.md](docs/COMO-REPORTAR.md) para enviar um relato útil.

## Estado da versão de testes

- **98 testes automatizados passaram:** 92 de gameplay/interface/rede, 2 de configuração e 4 de distribuição.
- Instalação a partir de ZIP extraído em pasta limpa validada no Windows PowerShell 5.1, incluindo download automático, compilação e conferência dos arquivos originais.
- Teste com **dois executáveis reais no mesmo PC**, conectados por TCP, verificou controles, papéis, dano, 747 estados recebidos e saída após fechar o anfitrião.
- Formulário LAN e lobby foram conferidos em 640×480.
- **Ainda precisa de teste entre dois PCs físicos**, incluindo firewall, Wi-Fi e sensação de resposta.
- O anfitrião calcula a partida; o convidado recebe o estado, sem predição/interpolação. A latência pode ser perceptível.

Veja o [relatório de validação deste pacote](docs/VALIDACAO-RELEASE.md).

## Atualização e desinstalação

Para atualizar, extraia a nova release em outra pasta e instale novamente. Para desinstalar, feche o jogo e exclua a pasta do mod. O instalador não cria serviço, tarefa agendada, regra de firewall nem entrada no registro. Placares são de sessão, sem salvamento permanente.

## Arquivos e publicação

O ZIP contém código do mod, instalador, documentação e testes. Os arquivos do jogo e a ferramenta de terceiros são obtidos localmente durante a instalação.

- [Guia de desenvolvimento](docs/DESENVOLVIMENTO.md)
- [Publicar no GitHub ou enviar o ZIP](docs/PUBLICAR.md)
- [Roteiro para testers e relatos de bugs](docs/COMO-REPORTAR.md)
- [Histórico técnico](docs/HISTORICO-TECNICO.md)
- [Créditos e componentes externos](THIRD_PARTY.md)

Projeto de fãs, sem afiliação oficial. DELTARUNE, personagens, arte, áudio e demais recursos do jogo pertencem aos respectivos titulares.
