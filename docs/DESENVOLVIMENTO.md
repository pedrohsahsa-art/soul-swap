# Desenvolvimento e instalação avançada

## Instalação do tester

`Install.cmd` chama `scripts/install.ps1` no Windows PowerShell 5.1. Não precisa de SDK nem runtimes de desenvolvimento. A execução com `ExecutionPolicy Bypass` é limitada àquele processo; não altera a política global.

O instalador valida os quatro arquivos em `release/compatibility.json`, baixa o ZIP oficial fixado por hash, verifica round-trip, compila seis eventos e reabre o arquivo para validação. Só depois publica a pasta jogável. Reinstalações preservam a pasta antiga; falha de publicação tenta restaurá-la.

Download offline/manual da ferramenta:

```powershell
powershell -NoProfile -STA -ExecutionPolicy Bypass -File scripts/install.ps1 `
  -GameDirectory 'D:\SteamLibrary\steamapps\common\DELTARUNE' `
  -ToolArchive 'D:\Downloads\UTMT_CLI_v0.9.2.0-Windows.zip'
```

Use exatamente o ZIP/link/hash de `release/compatibility.json`; não um executável de outra versão. A instalação temporária é removida ao terminar. O ZIP baixado fica em `.cache` para reinstalação; pode ser apagado para recuperar espaço.

## Fonte e testes

- Python **3.11+** para testes de configuração, build de desenvolvedor e empacotamento.
- Node.js **22+** para os testes de gameplay/rede com APIs simuladas.
- Windows + DELTARUNE compatível + UndertaleModCli **0.9.2.0** para compilar e executar o runner.

```powershell
node tests/controller.test.cjs
python tests/build_test.py
python tests/package_test.py
python scripts/package.py
```

Compilação de desenvolvedor (não usa o instalador PS):

```powershell
python build.py --rebuild `
  --game 'D:\SteamLibrary\steamapps\common\DELTARUNE' `
  --cli 'D:\Tools\UTMT\UndertaleModCli.exe'
```

Também aceita `DELTARUNE_DIR` e `UTMT_CLI` no ambiente. Nenhum caminho de pesquisa do computador do autor é necessário. O build de desenvolvedor exige Node/Python e roda os testes antes de compilar; o instalador para testers usa o código da release validada sem esses runtimes.

Teste real de dois runners por loopback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/lan-smoke.ps1
```

Esse teste usa explicitamente `--lan-test` para input sintético e ignorar a perda de foco entre suas duas janelas. Não use esse argumento numa partida normal. O relatório fica em `build/lan-smoke.json`. Capturas: `tests/ui-review.ps1`.

## Estrutura

```text
Install.cmd                   entrada do tester
Start_LAN.cmd                 entrada LAN + consulta IPv4
Start_Local_PvP.cmd            entrada local
scripts/install.ps1           instalação em staging, download e checksums
scripts/package.py            ZIP allowlist + manifesto + checksum
release/compatibility.json    versões/arquivos de entrada aceitos
gml/                          gameplay, desenho e networking
patch.csx / verify.csx         integração com UndertaleModCli
assets/*.json                 identificadores e metadados, sem imagens/áudio
tests/                        regressões e testes do runner
docs/                         guias e histórico
.github/                      CI e modelo de issue
```

`build`, `play*`, `.cache`, `.logs`, `dist` e imagens de referência são locais/ignorados. O empacotador usa lista explícita: um arquivo novo fora dela não entra automaticamente na release.
