# FocusFeed

MVP Flutter de Pomodoro offline com bloqueio de apps, saldo de recompensa de 20%
e histórico local. Código aberto sob licença MIT. Sem conta, backend, anúncios,
analytics ou conexão de rede em tempo de execução na versão Android release.

## Executar

SDK de referência: Flutter 3.47.7 / Dart 3.13.5, Java 17.

```sh
flutter pub get --enforce-lockfile
flutter run
flutter analyze
flutter test
cd android
./gradlew :app:testDebugUnitTest
./gradlew :app:connectedDebugAndroidTest
```

Os testes instrumentados precisam de um emulador/aparelho Android 13+ dedicado
com possibilidade de conceder appops pelo ADB. Eles modificam somente os dados
e permissões de teste do FocusFeed; não os execute com progresso pessoal importante.

## Uso

1. Autorize acesso ao uso e sobreposição no painel. Acessibilidade não é exigida.
2. Marque apps instalados e escolha 1, 5, 15, 25, 45 ou 60 minutos.
3. Inicie Foco. Apps selecionados recebem uma sobreposição com mensagem e retorno.
4. Uma conclusão bem-sucedida rende 20%: 25 minutos = 5 minutos; 1 minuto = 12 segundos.
5. Use o saldo para liberar redes temporariamente. O foco ativo fica congelado.
   No fim da recompensa, ele retoma pelo tempo restante; sem foco ativo,
   os apps voltam a ficar bloqueados até Parar, nova sessão ou nova liberação.

Saldo zero desabilita a recompensa e nunca libera apps por si só. A sobreposição
continua durante foco/bloqueio ativo e explica como ganhar saldo. Fora de um
foco/bloqueio ativo, não se impõe um bloqueio permanente só por ter saldo zero.
Pausar interrompe o foco e o bloqueio, preservando o restante. Parar cancela ambos,
sem crédito ou devolução de uma recompensa já usada. Há uma ação Parar na notificação.

## Estado, persistência e recuperação

`lib/session_controller.dart` coordena a apresentação e lê o estado nativo. A tela
não mantém outro saldo nem credita sessões independentemente. A cada segundo e
ao retornar ao app, consulta sessão, permissões, monitor e notificações.

Android: `SessionEngine.kt` contém a máquina de estados testável. O serviço avança
o relógio monotônico e `NativeSessionRepository.kt` salva um snapshot versionado
em SharedPreferences privado. Saldo, seleção, histórico, fase, identidade e prazos
são escritos juntos. Um ID de sessão e a lista de conclusões evitam crédito duplo.
As gravações e os comandos compartilham uma fila; o débito e a janela de recompensa
são persistidos antes da liberação. O formato anterior v1 é migrado sem perder
saldo fracionário, histórico e os três pacotes selecionados.

Fechar a interface não interrompe o serviço. Se o processo for encerrado pelo
sistema, START_STICKY permite que o Android tente restaurar o monitor. Se ele não
estiver executando ao reabrir, o foco é restaurado pausado no último checkpoint
(até 5 segundos de diferença) e a tela explica a interrupção. Não se concede
recompensa por tempo sem monitor. O reinício do aparelho pausa o foco, preserva
saldo/histórico e não credita tempo desligado. Recompensa interrompida não é
reembolsada. Um receiver registra o reinício e, se permitido, avisa o usuário;
não inicia uma tela ou serviço automaticamente no boot.

Os totais diários contam sessões concluídas na data local de conclusão, inclusive
após retorno tardio. Uma sessão que atravessa meia-noite é atribuída inteiramente
ao dia em que termina. Trocar de dia não apaga dias anteriores nem o saldo.

## Notificações e limites Android

A autorização de notificações é opcional (POST_NOTIFICATIONS em Android 13+).
Há uma notificação persistente de monitor, uma de foco concluído com o crédito
real calculado, e uma com “Seu tempo de pausa acabou!” ao expirar a recompensa.
Negar notificações não impede foco/bloqueio. O app mostra o estado da autorização.
Sem alarmes exatos ou wakelock, notificações/callbacks podem atrasar durante Doze.
O prazo monotônico não se estende artificialmente quando o aparelho volta a executar.

Monitoramento de UsageEvents a cada 500 ms; a lista mostra apenas apps com launcher
visíveis no perfil atual, sem QUERY_ALL_PACKAGES. Home, controles do sistema e
Parar continuam acessíveis. Fabricantes, modo multiwindow, permissões revogadas,
interrupção pelo gerenciador do Android e apps que escondem overlays podem limitar
ou interromper a proteção. A tela sinaliza proteção indisponível, e perda de
permissão pausa o foco. Não é um controle parental inviolável.

## iOS — configuração e validação pendente

O código inclui FamilyActivityPicker, shields do ManagedSettings, monitor
DeviceActivity e duas extensões para configuração/ação do shield. Runner embute
FocusMonitor, FocusShield e FocusShieldAction. Os quatro targets usam Family
Controls e o App Group `group.io.github.alunoadsnoite.focusfeed`.

No Mac/Xcode, configure uma equipe e provisionamento nos quatro targets, registre
o App Group e os Bundle IDs `io.github.alunoadsnoite.focusfeed` e seus sufixos.
Para distribuição, solicite a aprovação de Family Controls à Apple para os targets
necessários. Os snapshots e tokens são locais no App Group; um lock de arquivo
coordena Runner e extensões e impede conclusões duplicadas. UserDefaults anterior
é migrado; o JSON compartilhado tem escrita atômica. O manifesto de privacidade
inclui UserDefaults para migração e relógio monotônico para medir os intervalos.

DeviceActivity exige intervalos de monitoramento de pelo menos 15 minutos. Janelas
curtas usam um intervalo já em andamento com início retroativo, mantendo o fim
real da pausa/foco. Se o sistema recusar o agendamento, a alteração é desfeita e o
saldo é preservado. Os callbacks dependem do uso do dispositivo; não há garantia
de callback instantâneo com o aparelho ocioso. Após reinício/alteração relevante
de relógio, a sessão é pausada sem crédito por interrupção.

Em iOS anteriores a 26.5, o shield não oferece uma API pública para abrir diretamente
o app pai. O botão fecha o app bloqueado e envia uma notificação de retorno, que
abre o FocusFeed ao ser tocada; sem notificações, abra o FocusFeed manualmente.
Com SDK/iOS 26.5+, é possível habilitar `FOCUSFEED_OPEN_PARENT_APP` nas condições
Swift do target FocusShieldAction para usar a resposta pública de abertura.

**Esta implementação iOS não foi compilada nem validada em iPhone neste ambiente
Linux.** Há testes XCTest no RunnerTests e CI de compilação de simulador; aprovação
e funcionamento em aparelho continuam dependentes de Xcode, assinatura e entitlement.
Não publique um binário iOS como validado antes dessas verificações.

## Distribuição

```sh
python3 scripts/create_signing_key.py
flutter build apk --release
```

A chave e suas senhas ficam em `.private/` ignorado pelo Git. Faça um backup privado;
a mesma chave é necessária para atualizar instalações distribuídas diretamente.
Para build sem assinatura destinado ao F-Droid: `FOCUSFEED_UNSIGNED=1 flutter build apk --release`.
O pacote Android é `io.github.alunoadsnoite.focusfeed`, versão 1.0.1 (2).
F-Droid constrói/assina sua própria versão após revisão; submissão não é aprovação.
Metadados Fastlane estão em `fastlane/metadata/android` e a proposta de receita em
`fdroid/`. O status da publicação e a evidência de testes ficam em `docs/`.
