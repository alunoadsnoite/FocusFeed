# Proposta para o catálogo oficial F-Droid

A receita `io.github.alunoadsnoite.focusfeed.yml` prepara a versão 1.0.1 com três
builds separados: ARMv7 (4011), ARM64 (4012), x86_64 (4013). Os códigos seguem `versionCode base * 10 + ABI (1/2/3)`. O código do Flutter
é fixado pela revisão `.metadata`; a receita respeita `pubspec.lock` e não inclui
material de assinatura. O F-Droid constrói e assina os APKs após revisão.

A descrição completa da submissão está em `MR_DESCRIPTION.md`, derivada do
template oficial App inclusion. As exceções de srclib do SDK, assinatura e as
verificações ainda dependentes do CI são explicitamente descritas.

Os metadados Fastlane incluem descrições en-US/pt-BR, ícones, changelogs e quatro
capturas reais. O teste instrumentado confirma a mensagem de bloqueio sobre um
alvo que permite overlays; Configurações do Android oculta overlays por segurança.

Os detalhes da validação e os limites estão em `docs/VALIDATION.md`.

O número base passa de 2 para 401 para que todos os novos APKs ultrapassem o maior código antigo (4002). A versão exibida continua 1.0.1; as tags existentes não são movidas.

A tag adicional `v1.0.1-fdroid.1` aponta ao commit com o novo número base; `v1.0.1` permanece inalterada. A detecção de atualizações do F-Droid pode identificar a preparação sem mover uma tag existente.
