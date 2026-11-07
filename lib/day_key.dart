/// Chave de data local (`AAAA-MM-DD`) usada pelo histórico de foco.
///
/// O histórico nativo e a interface precisam concordar sobre o dia local de
/// conclusão, inclusive perto da meia-noite.
String localDayKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
