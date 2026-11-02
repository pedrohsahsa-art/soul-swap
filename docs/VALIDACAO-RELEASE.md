# Validação de referência — 0.8.0-test.1

Registro da validação completa da primeira release. A versão `0.8.0-test.2` troca a origem da música para `mus/joker.ogg`, preservando o gameplay e o protocolo 0.8.0.

## Atualização test.3 — desempenho LAN

- 90 testes de gameplay/rede, 2 de configuração e 4 de distribuição passaram.
- Simulação determinística de 100 ms de RTT, com 30 ticks/s: antes, 20 estados/s recebidos; depois, 30 estados/s. Medição do transporte simulado, não de CPU/GPU do GameMaker.
- Janela limitada a oito estados; o teste de convidado parado confirma limite de fila, pausa e timeout.
- Instalação limpa compilada e reaberta com sucesso. Dois runners reais passaram: 621 ticks sincronizados, 3 trocas, 130 de dano acumulado e detecção de anfitrião encerrado.
- Captura do convidado exibiu 30 FPS, ping 34 ms e REDE 30/s. HUD inspecionado também em resolução nativa.
- O PC do amigo não foi perfilado; queda de FPS nesse hardware continua a exigir verificação. A taxa do jogo permanece em 30 FPS, sem interpolação/predição no cliente.

## Música — test.2

Instalação a partir de ZIP extraído em uma pasta nova concluída no Windows PowerShell 5.1, usando o ZIP oficial da ferramenta já em cache. A compilação e a reabertura dos seis eventos passaram; os arquivos originais foram conferidos. O `battle.ogg` instalado corresponde exatamente a `mus/joker.ogg` (**THE WORLD REVOLVING**), SHA-256 `59aa09ed117bb057112befa4f740143e207d8f8d8a7d03e5b0f37f44240fe74d`.

## Testes automatizados

- `node tests/controller.test.cjs`: **88 passaram**, incluindo as 45 combinações de ataques e os casos LAN.
- `python tests/build_test.py`: **2 passaram**.
- `python tests/package_test.py`: **4 passaram**, incluindo exclusão de arquivos do jogo/ferramentas, manifesto SHA-256, reprodução do ZIP e consistência das versões.
- Scripts PowerShell analisados pelo parser do **Windows PowerShell 5.1**, sem erros.

## Instalação de tester

Testada a partir do ZIP extraído em uma pasta nova, fora da árvore de desenvolvimento, com caminho contendo espaços. O teste usou o Windows deste computador, não uma instalação limpa do sistema operacional.

- Descoberta automática do DELTARUNE Steam e `-ValidateOnly` funcionaram.
- Download real do ZIP oficial de UndertaleModCli e conferência do hash funcionaram.
- Leitura/escrita sem modificação foi idêntica ao original.
- Compilação e reabertura verificaram os seis eventos do controlador.
- A instalação usou PowerShell e a ferramenta baixada; não invocou Python, Node, Git nem .NET SDK.
- Os quatro arquivos originais mantiveram os hashes esperados.
- O arquivo instalado `data.win` foi idêntico ao build v0.8.0 previamente validado: `e328d820d657cfb70465dcd2d8ddd46ec8b6476b91672c2155cfc7a87b2a7537`.
- Caminho inexistente, arquivo ausente, jogo incompatível, ferramenta com hash incorreto e instalação dentro da pasta do jogo foram recusados.
- Uma segunda instalação sem `-Reinstall` foi recusada; falha na ferramenta limpou o staging sem publicar um build.
- `-Reinstall` reutilizou o download em cache, preservou integralmente a pasta anterior e produziu o mesmo arquivo compilado; o staging foi removido ao terminar.

## Execução do pacote instalado

- Lobby local e formulário LAN abriram e foram inspecionados visualmente em resolução nativa.
- Dois runners do pacote instalado passaram no teste TCP por loopback: **624 ticks no host, 623 no cliente, 3 trocas e 100 de dano acumulado**.
- O cliente detectou o encerramento do anfitrião e saiu da sessão.

## Cobertura pendente

- Dois computadores físicos, redes Wi-Fi distintas e configurações de firewall dos testers.
- Avaliação humana da resposta do cliente sob latência.
- Instalação em outras máquinas Windows 10/11; outras builds do jogo não são suportadas por este pacote.
- A release test.1 foi publicada e os testes passaram no [GitHub Actions](https://github.com/pedrohsahsa-art/soul-swap/actions/runs/41326239909).
