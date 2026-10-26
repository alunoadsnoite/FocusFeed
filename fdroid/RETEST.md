# Reteste funcional para a F-Droid

Versão: 1.0.2, ARM64 4022. Fonte:
`d2c3b34d730e90426cd7ef184af07baa4d6b8a51`.
[MR !52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413).

A reprodução original ocorreu com APKPure em Samsung SM-G998B / Android 15.
Um resultado em emulador complementa, mas não encerra essa pendência.
Use um aparelho de teste e não substitua uma instalação com dados importantes.
Os APKs assinados do pipeline são artefatos de teste, não publicação oficial.

1. Registrar modelo, versão do Android, versão/código e origem do APK, versão
   do APKPure e configurações de bateria aplicadas ao FocusFeed.
2. Conceder acesso de uso e sobreposição pela interface do app. Selecionar
   APKPure e deixar outro app comum não selecionado.
3. Iniciar foco de um minuto com saldo zero. Abrir APKPure, registrar se a
   mensagem de foco fica visível e a latência observada. Retornar ao FocusFeed
   e repetir a abertura. O bloqueio deve aparecer nas duas tentativas.
4. Abrir o app não selecionado durante o foco. Ele deve permanecer utilizável.
5. Concluir o minuto de foco. O saldo deve aumentar exatamente 12 segundos,
   uma única vez. Resgatar o saldo e abrir APKPure durante a recompensa:
   ele deve ficar utilizável.
6. Manter APKPure aberto até expirar a recompensa. A mensagem de bloqueio
   deve reaparecer e o saldo deve zerar, sem callback da interface Flutter.
7. Registrar resultado por etapa, latências e capturas. Se houver falha,
   registrar se o monitor permanece ativo e se o Android suprimiu a janela.
   Compartilhar somente logs filtrados e revisados, sem dados de outros apps.

Não usar Configurações do Android como alvo de bloqueio: ele pode ocultar
overlays por segurança. Não desativar proteções do Android para fazer o teste passar.
Não marcar o problema original como resolvido sem confirmar no aparelho afetado.
