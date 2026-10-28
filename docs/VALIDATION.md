# Validação do MVP

## Atualização consultada — 27/10/2026

A API da MR !52413 confirma submissão aberta, sem conflitos e pipeline
#2987337391 aprovado. O PR upstream #4 já está integrado. O catálogo para
`io.github.alunoadsnoite.focusfeed` retornou 404; não se declara publicação.

A descrição da [MR](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413)
registra teste do autor em Samsung SM-X510 / Android 16, com FocusFeed 1.0.2
ARM64 4022 e APKPure 3.20.81: duas aberturas bloqueadas, app não selecionado
acessível, crédito, resgate e retorno do bloqueio após expiração pela interface.
É um relato já publicado, não um novo teste físico desta revisão. O APK usava
certificado de desenvolvimento; não era assinado pelo F-Droid. Esse ensaio
não substitui o caso original SM-G998B / Android 15 nem a aceitação independente.
Os trechos datados abaixo preservam o escopo das verificações anteriores.

## Estado atual do F-Droid — 26/10/2026

A [MR !52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413) está aberta
com a versão 1.0.2, tag `v1.0.2`, fonte
`d2c3b34d730e90426cd7ef184af07baa4d6b8a51` e número base 402. Os códigos
ARMv7/ARM64/x86_64 são 4021/4022/4023 (`base * 10 + ABI`). A receita neste
repositório espelha a receita submetida no commit fdroiddata
`00c3d8f2610b725de05049beea534d3433591172`; atualizações por tags permanecem ativas.

O [pipeline #2987337391](https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/2987337391)
passou as nove etapas: build das três arquiteturas, APK, código-fonte, schema,
scripts, rewritemeta, lint, redirecionamento Git e detecção de atualizações.
Os resultados foram consultados em 26/10/2026. CI aprovado não confirma
aceitação nem publicação no catálogo.

O [relatório de qualidade](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413/reports/code-quality)
contém 32 descobertas: três avisos Minor sobre SYSTEM_ALERT_WINDOW (um por ABI)
e 29 informações sobre permissões, R8, tamanho/ABI, APKs de teste e Fastlane.
SYSTEM_ALERT_WINDOW desenha o bloqueador voluntário; PACKAGE_USAGE_STATS consulta
os eventos locais de primeiro plano. FOREGROUND_SERVICE e SPECIAL_USE mantêm o
monitor iniciado pelo usuário; POST_NOTIFICATIONS permite notificações opcionais;
RECEIVE_BOOT_COMPLETED recupera progresso pausado sem crédito de tempo desligado.
DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION é a proteção de receivers gerada pelo
AndroidX. Os links de APK assinado são artefatos de CI para teste e não comprovam
assinatura ou distribuição no catálogo oficial. Não há permissão INTERNET no
manifest de release. Nenhum aviso foi ocultado nem permissão necessária removida.

O tester relatou ausência de bloqueio do APKPure em duas aberturas no Samsung
SM-G998B / Android 15 com a versão 1.0.1. A versão 1.0.2 inclui rastreamento por
pacote/Activity e uma janela sobreposta de eventos de 10 segundos, além de
changelogs para 4021/4022/4023 nos dois idiomas. Essas mudanças ainda não
estabelecem a causa nem comprovam a resolução naquele aparelho. Continua
necessário retestar duas aberturas consecutivas, acesso a app não selecionado,
resgate de saldo e bloqueio após expiração no Samsung. Capturas en-US mostram
a interface portuguesa, conforme declarado na submissão.

A assinatura reproduzível upstream e Screen Time em iPhone continuam pendentes;
a receita solicita assinatura pelo F-Droid. Apps que ocultam overlays podem
suprimir o bloqueador por proteção do Android. A aceitação depende dos mantenedores.

## Verificações locais — 26/10/2026

Na fonte `d2c3b34d730e90426cd7ef184af07baa4d6b8a51`:

- `flutter analyze`: sem problemas.
- `flutter test`: 20 testes aprovados.
- `:app:testDebugUnitTest`: 17 testes JVM aprovados (13 SessionEngine e 4 ForegroundActivityTracker).
- `:app:assembleDebugAndroidTest`: APK de instrumentação compilado; não executado.
- `FOCUSFEED_UNSIGNED=1 flutter build apk --debug`: aprovado.
- Receita YAML analisada, idêntica byte a byte à submetida; fonte, versões,
  códigos e seis changelogs 4021–4023 verificados.

### Aparelho físico — Motorola Edge 70 Fusion / Android 17 (API 37)

Sete testes instrumentados passaram em 26/10/2026 (38,481 s): bloqueio visível
com saldo zero; duas aberturas consecutivas com retorno ao FocusFeed; app não
selecionado sem overlay por três segundos; crédito persistido e notificação;
expiração da recompensa e retorno ao bloqueio; revogação de permissão; migração.

O APK debug da fonte 1.0.2 foi instalado com sufixo `.debug`, separado da instalação
do usuário. O alvo é uma Activity de outro APK de teste que permite overlays,
não APKPure. Não foram apagados dados do pacote de produção. A suíte concede
permissões à cópia debug e inicia sessões curtas pelo repositório nativo; isso
não substitui um teste manual completo dos botões de resgate no APK release.

A primeira rodada passou 5/6 e falhou ao retornar à Activity Flutter usando
`startActivitySync`, que esperava a fila ficar inativa por 45 segundos. A tela
também entrou em repouso nessa rodada. O teste agora inicia a Activity de forma
assíncrona e mantém a exigência de desaparecimento do overlay no retorno e de
mensagem visível em cada nova abertura. O segundo ensaio, com a tela desbloqueada,
passou 7/7. Nenhuma mudança no código de execução do app foi necessária.

Os emuladores Android 16 e 11 encerraram com segmentation fault antes desta rodada
física. O caso Samsung SM-G998B / Android 15 / APKPure continua sem confirmação;
[fdroid/RETEST.md](../fdroid/RETEST.md) descreve o roteiro específico pendente.

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
