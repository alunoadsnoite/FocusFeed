# Proposta para o catálogo oficial F-Droid

A receita io.github.alunoadsnoite.focusfeed.yml segue o template Flutter oficial,
usa o SDK upstream 3.47.7, respeita pubspec.lock e não inclui material de assinatura.
O F-Droid deverá construir e assinar o APK com a infraestrutura própria.

Licença MIT. Não há serviços proprietários, SDK de analytics, anúncios ou backend.
A permissão de Internet existe só nos manifests de debug/profile do Flutter;
o release não a declara. Uso de apps é consultado localmente para o overlay.

Descrições, ícone e capturas ficam em fastlane/metadata/android. A build local
Android é validada; a receita deve passar pelo lint/build e pela revisão dos
mantenedores no ambiente F-Droid antes de ser aceita no catálogo.
