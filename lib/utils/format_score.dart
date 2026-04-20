/// Formats an integer score with comma thousands separators.
/// Examples: 0 -> "0", 1234 -> "1,234", -1234567 -> "-1,234,567".
String formatScore(int score) {
  final s = score.abs().toString();
  final withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m.group(1)},',
  );
  return score < 0 ? '-$withCommas' : withCommas;
}
