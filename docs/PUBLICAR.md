# Enviar aos testers / publicar no GitHub

## Envio direto

Execute `python scripts/package.py`. Envie somente:

- `dist/SOUL-SWAP-0.8.0-test.2.zip`
- `dist/SOUL-SWAP-0.8.0-test.2.zip.sha256`

O tester extrai o ZIP e abre `Install.cmd`. O instalador usa a instalação própria de DELTARUNE. O manifesto interno lista o SHA-256 de cada arquivo distribuído.

## Pelo site do GitHub, sem Git instalado

1. Entre na sua conta e crie um repositório chamado, por exemplo, **soul-swap**.
2. Extraia o ZIP em uma pasta nova. Use **Add file → Upload files** para enviar **o conteúdo interno da pasta SOUL-SWAP**, deixando `README.md` na raiz do repositório. Inclua `.github`, `.gitignore` e `.gitattributes` (nomes começando com ponto).
3. Em **Releases → Draft a new release**, crie a tag **`v0.8.0-test.2`**, título **SOUL / SWAP 0.8.0-test.2 — THE WORLD REVOLVING**, e marque **pre-release**.
4. Anexe o ZIP e o `.sha256` acima. Use [RELEASE-NOTES.md](RELEASE-NOTES.md) como descrição.
5. Envie o link da release aos testers. Eles precisam baixar o ZIP do pacote e seguir o README.

O GitHub pode exigir uma permissão adicional para enviar workflows; nesse caso, adicione `.github/workflows` pelo editor do site ou por Git autenticado. A instalação do mod não depende de GitHub Actions.

## Por Git/CLI

Em uma cópia limpa extraída do ZIP (Git e `gh` instalados/autenticados):

```powershell
git init
git add .
git commit -m "Prepare SOUL SWAP LAN tester release"
git branch -M main
gh repo create soul-swap --public --source . --remote origin --push
python scripts/package.py
gh release create v0.8.0-test.2 `
  dist/SOUL-SWAP-0.8.0-test.2.zip `
  dist/SOUL-SWAP-0.8.0-test.2.zip.sha256 `
  --prerelease --title "SOUL SWAP 0.8.0 - teste LAN" --notes-file docs/RELEASE-NOTES.md
```

Escolha a visibilidade do repositório conforme seu grupo de testes. O CI executa os testes simulados/configuração e verifica o pacote; não possui o jogo original, portanto não compila nem testa o runner em GitHub Actions. O workflow de release por tag pode ser acionado quando a tag for enviada por Git; ele publica o mesmo pacote após os testes.

## O que publicar

Publique a pasta limpa de código gerada pelo empacotador. Builds antigos, logs, executáveis, `data.win`, áudio, imagens extraídas e downloads de ferramentas ficam fora do pacote. A árvore de trabalho do autor mantém esses arquivos locais para desenvolvimento.

Esta preparação não cria conta, repositório remoto nem URL pública automaticamente.
