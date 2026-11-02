# Testar e reportar problemas

## Um roteiro curto para dois testers

1. Instalar nos dois PCs e confirmar a mesma release.
2. Hospedar/conectar por IPv4 e porta; registrar se é cabo ou Wi-Fi.
3. P1 atacar, P2 defender; completar a troca e testar P2 atacando.
4. Selecionar dois ataques diferentes e alternar pela roda.
5. Testar Costura, Bumerangue e Jardim, incluindo clique direito e cancelamento de gestos.
6. Abrir AJUDA, voltar, pausar, tirar/restaurar foco e conferir que os dois veem o mesmo estado.
7. Desconectar, hospedar novamente e reconectar.

## Modelo de relato

```text
Versão do pacote: 0.8.0-test.4
FPS / PING / REDE por segundo nos dois PCs durante a travada:
Windows dos dois PCs:
Modo: local / LAN
Papel de quem observou: anfitrião / convidado
Rede: cabo / Wi-Fi / VPN
Ataques equipados:
Passos para reproduzir:
1.
2.
Esperado:
O que aconteceu:
Acontece sempre ou às vezes?
Mensagem de erro / captura:
```

Para erro de instalação, anexe o log mais recente em `.logs`. Ele pode incluir caminhos de pastas e o nome do usuário do Windows: você pode ocultar esses trechos antes de publicar. Não é necessário anexar executável, `data.win` ou arquivos de áudio.

Se o repositório já estiver publicado, abra **Issues → Reportar bug**. Se recebeu apenas o ZIP, envie o relato à pessoa que o forneceu.
