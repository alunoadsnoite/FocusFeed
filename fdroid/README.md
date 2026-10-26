# Proposta para o catálogo oficial F-Droid

A receita `io.github.alunoadsnoite.focusfeed.yml` espelha a submissão da versão
1.0.2 na [MR !52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413).
Fixa a fonte `d2c3b34d730e90426cd7ef184af07baa4d6b8a51` (tag `v1.0.2`),
com builds ARMv7 (4021), ARM64 (4022) e x86_64 (4023).
Os códigos seguem `versionCode base * 10 + ABI (1/2/3)` e preservam upgrades.
O SDK Flutter é fixado pela revisão de `.metadata`; `pubspec.lock` é respeitado
e `FOCUSFEED_UNSIGNED=1` exclui a configuração de assinatura do desenvolvedor.

O pipeline #2987337391 passou as nove etapas, incluindo as três arquiteturas.
O relatório tem avisos de sobreposição e informações de permissões/APKs,
explicados em [docs/REVIEW.md](../docs/REVIEW.md). Isso não confirma publicação.

Ainda falta reteste independente do bloqueio no Samsung SM-G998B / Android 15,
incluindo APKPure em duas aberturas, app não selecionado, resgate e expiração.
A correção de eventos de primeiro plano não estabelece a causa no Samsung.
Os metadados Fastlane incluem descrições en-US/pt-BR, ícones, changelogs para
4021–4023 e quatro capturas reais com interface portuguesa.

`MR_DESCRIPTION.md` contém o texto de referência da submissão; resultados locais
e limites ficam em [docs/VALIDATION.md](../docs/VALIDATION.md).
