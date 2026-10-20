# Validação do MVP

## Estado atual do F-Droid — 20/10/2026

A [MR !52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413) usa a tag `v1.0.1-fdroid.1`, fonte `3170e6e86357c2ec814d4e69be02c78b4c134499`, versão 1.0.1 e número base 401. A receita gera códigos 4011/4012/4013 para ARMv7/ARM64/x86_64, preservando atualização sobre os códigos antigos 1002/2002/4002. Atualizações por tags estão configuradas.

Segundo a MR, as nove etapas passaram no [pipeline do fork #2963844433](https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/2963844433) e no [pipeline acionado pelo mantenedor #2963950139](https://gitlab.com/fdroid/fdroiddata/-/pipelines/2963950139), incluindo os três builds e verificações de APK. Estes são resultados publicados para a fonte submetida, não testes novamente executados nesta atualização documental.

A validação independente solicitada pelo mantenedor continua pendente. O teste anterior de overlay foi corrigido para usar uma Activity de outro APK que permite sobreposição, preservando a exigência de mensagem visível. As restrições de Configurações e de outros apps que ocultam overlays continuam sendo limites reais do Android.

A assinatura reproduzível upstream não foi verificada; a receita solicita assinatura pelo F-Droid. Testes de Screen Time em iPhone continuam pendentes fora do escopo Android. Aprovação do CI não significa aprovação ou publicação no catálogo.

Os registros abaixo são históricos; versões, códigos e falhas antigas devem ser lidos nas respectivas datas.


Ambiente: Flutter 3.47.7 / Dart 3.13.5, Java 17, Android 14 (API 34) em emulador
headless temporário, somente leitura do AVD original. Nenhum aparelho físico
Android ou iPhone estava conectado.

Verificações realizadas:
- flutter analyze: sem problemas.
- flutter test: 20 testes aprovados (controlador, UI, saldo, migração v1).
- Testes JVM: 13 cenários — conclusão idempotente, pausa, cancelamento, débito, saldo zero,
  expiração de recompensa, retorno tardio, reinício, relógio alterado e snapshot.
- Cinco testes instrumentados: overlay com saldo zero; crédito/notificação após
  foco; recompensa expirando e reativando overlay; revogação de permissão;
  migração do progresso anterior.

A primeira rodada instrumentada encontrou uma condição de corrida na abertura:
um initialize/status podia marcar o monitor como interrompido antes de o FGS
iniciar. Foi adicionada uma janela curta de inicialização sem avanço/crédito;
a rodada seguinte passou os cinco cenários.

Limites: emulador não representa as políticas de bateria de todos os fabricantes.
iOS inclui fontes, targets e XCTest, mas precisa de compilação no CI/Mac e testes
em aparelho com assinatura/App Groups/Family Controls para validar Screen Time.

O APK release foi instalado e iniciado no emulador. Assinatura RSA 4096/v2 verificada; sem permissão INTERNET no release.

## Revalidação após as mudanças de Hermes/OpenCode — 2026-10-13

No commit f967a90, flutter analyze, 20 testes Flutter, compilação Android debug
e a tarefa de 13 testes JVM passaram. O CI GitHub também aprovou a compilação
Android e a compilação iOS para simulador (não substitui Screen Time em aparelho).

A rodada atual dos cinco testes instrumentados passou quatro cenários e falhou
em zeroBalanceStillShowsOverlayForSelectedApp, NativeFlowTest.kt:79. O indicador
de janela criada passou, mas a busca pela mensagem visível via UiAutomation
não passou. A aprovação anterior referia-se ao teste menos rigoroso, que apenas
verificava a criação da janela. O overlay continua com validação pendente;
compilar o app não comprova o bloqueio visual.

Detalhes da revisão e publicação: [REVIEW.md](REVIEW.md).

## Revalidação para o F-Droid — 2026-10-14

Flutter analyze sem problemas, 20 testes Flutter e 13 testes JVM aprovados.
Os cinco testes instrumentados passaram em uma cópia temporária do emulador
Android 14. A falha anterior era causada pelo alvo Configurações do Android:
a janela estava oculta por `mForceHideNonSystemOverlayWindow=true`. O teste
agora usa uma Activity de outro APK de teste que permite sobreposições e
continua exigindo a mensagem visível. A captura do bloqueio foi salva somente
após essa verificação passar. Nenhuma proteção do Android foi desativada.

Capturas reais de início, foco ativo, lista de apps e bloqueio foram adicionadas
aos metadados pt-BR e en-US. A interface permanece em português.

Build release 1.0.1 por arquitetura aprovado: ARMv7 ~14,3 MB (1002),
ARM64 ~17,0 MB (2002), x86_64 ~18,4 MB (4002). A receita usa os offsets
de ABI do Flutter e VercodeOperation para manter atualizações automáticas.

A assinatura reproduzível upstream ainda não foi validada; o F-Droid usa sua
própria assinatura. A aceitação e publicação dependem da revisão e CI do F-Droid.
