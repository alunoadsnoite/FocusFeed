# Revisão das mudanças de Hermes/OpenCode

## Estado atual do F-Droid — 20/10/2026

A [MR !52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413) usa a tag `v1.0.1-fdroid.1`, fonte `3170e6e86357c2ec814d4e69be02c78b4c134499`, versão 1.0.1 e número base 401. A receita gera códigos 4011/4012/4013 para ARMv7/ARM64/x86_64, preservando atualização sobre os códigos antigos 1002/2002/4002. Atualizações por tags estão configuradas.

Segundo a MR, as nove etapas passaram no [pipeline do fork #2963844433](https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/2963844433) e no [pipeline acionado pelo mantenedor #2963950139](https://gitlab.com/fdroid/fdroiddata/-/pipelines/2963950139), incluindo os três builds e verificações de APK. Estes são resultados publicados para a fonte submetida, não testes novamente executados nesta atualização documental.

A validação independente solicitada pelo mantenedor continua pendente. O teste anterior de overlay foi corrigido para usar uma Activity de outro APK que permite sobreposição, preservando a exigência de mensagem visível. As restrições de Configurações e de outros apps que ocultam overlays continuam sendo limites reais do Android.

A assinatura reproduzível upstream não foi verificada; a receita solicita assinatura pelo F-Droid. Testes de Screen Time em iPhone continuam pendentes fora do escopo Android. Aprovação do CI não significa aprovação ou publicação no catálogo.

Os registros abaixo são históricos; versões, códigos e falhas antigas devem ser lidos nas respectivas datas.


Data: 2026-10-13. Código analisado: f967a90 e mudanças desde db6969c.
GitHub/main e GitLab/main estavam iguais ao HEAD local ao iniciar a revisão.
Não é possível atribuir cada commit a uma ferramenta somente pelo histórico Git.

## Resultados

- Flutter analyze: sem problemas; 20 testes Flutter aprovados.
- Android debug: compilação aprovada; tarefa JVM aprovada, relatório com 13 testes sem falhas.
- Android 14, emulador biblia-capturas: quatro de cinco testes instrumentados aprovados.
- GitHub Actions: Android e simulador iOS aprovados no commit f967a90.
- GitLab: pipeline 2944613240 aprovado no mesmo commit.

## Pendências funcionais

1. O teste de overlay com saldo zero falha ao procurar a mensagem na janela
   (NativeFlowTest.kt:79). BlockingOverlay.visible só comprova addView, não a
   apresentação efetiva da mensagem. A mudança de contexto da janela ainda
   precisa de diagnóstico e confirmação visual antes de declarar o bloqueio validado.
2. A taxa configurável de RewardWallet é um helper Dart sem integração com o
   estado nativo ou com a UI. Android SessionEngine e iOS SessionCore continuam
   creditando tempo / 5. Além disso, Dart usa round enquanto ambos os motores
   nativos truncam; por exemplo, 8 segundos dão 2 no helper e 1 no motor.
   A validação da taxa também não rejeita NaN explicitamente. Os testes atuais
   usam durações divisíveis por cinco e não exercitam esses casos.
3. Screen Time em aparelho iOS continua pendente. A compilação de simulador
   aprovada confirma compilação, mas não autorização, monitoramento ou shields
   com os entitlements de distribuição.

## Publicação

GitHub: https://github.com/alunoadsnoite/FocusFeed

GitLab: https://gitlab.com/alunoadsnoite/FocusFeed

F-Droid: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413

O pipeline F-Droid 2944614181 passou build, lint, schema e verificações de
código/APK. Falhou exclusivamente no rewritemeta: as categorias precisam
estar em ordem alfabética (Time Tracker antes de Timer). Essa ordem foi
corrigida na receita local e na branch da proposta; lint e rewritemeta locais
foram reexecutados sem diferenças de formatação.

A proposta continua aberta e depende da revisão dos mantenedores. A tag
v1.0.0 aponta para 85ad306; a mudança posterior de receita não altera o
comportamento do APK dessa tag. Não há release GitHub com APK anexado.
Nenhuma tag foi movida e nenhuma nova versão do aplicativo foi criada nesta revisão.

## Atualização de 2026-10-14

A pendência 1 foi diagnosticada e resolvida no teste: Configurações do Android
oculta overlays por segurança. Os cinco cenários passaram usando um APK de
teste compatível; a mensagem foi verificada e capturada. Veja VALIDATION.md.
O helper de taxa variável continua sem integração; o produto anuncia somente
a taxa fixa de 20%, usada pelos motores nativos. A validação iOS em aparelho
continua pendente e não faz parte do pacote Android submetido ao F-Droid.
