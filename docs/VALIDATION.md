# Validação do MVP

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
