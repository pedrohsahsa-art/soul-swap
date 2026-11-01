# Baseline de comparacao

Eventos do controlador proprio do mod v0.6.2, copiados de `build/verified-code` antes de compilar a v0.7.0. Foram produzidos pela reabertura/decompilacao do arquivo da v0.6.2 pelo verificador do projeto. Os IDs numericos de sprites pertencem ao arquivo original; o benchmark nao desenha esta baseline.

O teste comparativo executa Create/Step antigos e atuais com a mesma sequencia deterministica de mouse por ataque. Mede ocupacao de 528 pontos da arena por segmentos de projeteis ativos durante 450 ticks. O defensor fica invulneravel para que acertos nao removam projeteis. Avisos nao contam como ameacas.

Essa medicao detecta regressoes de cobertura e persistencia. Nao mede habilidade humana, justica de todas as combinacoes ou probabilidade de vitoria. O relatorio sai em `build/pressure-comparison.json`.
