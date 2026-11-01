# Validação — 0.8.0-test.1

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
- Workflows preparados para GitHub Actions, ainda não executados no GitHub. Nenhum repositório remoto ou release foi publicado nesta preparação.
