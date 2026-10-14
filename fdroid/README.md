# Proposta para o catálogo oficial F-Droid

A receita `io.github.alunoadsnoite.focusfeed.yml` prepara a versão 1.0.1 com três
builds separados: ARMv7 (1002), ARM64 (2002), x86_64 (4002). O código do Flutter
é fixado pela revisão `.metadata`; a receita respeita `pubspec.lock` e não inclui
material de assinatura. O F-Droid constrói e assina os APKs após revisão.

A descrição completa da submissão está em `MR_DESCRIPTION.md`, derivada do
template oficial App inclusion. As exceções de srclib do SDK, assinatura e as
verificações ainda dependentes do CI são explicitamente descritas.

Os metadados Fastlane incluem descrições en-US/pt-BR, ícones, changelogs e quatro
capturas reais. O teste instrumentado confirma a mensagem de bloqueio sobre um
alvo que permite overlays; Configurações do Android oculta overlays por segurança.

Os detalhes da validação e os limites estão em `docs/VALIDATION.md`.
