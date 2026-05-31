/// Extract the one-sentence verdict from an `ActivityFeedbackAgent`
/// reply. The agent's prompt opens every response with a markdown-bold
/// summary sentence:
///
///     **Strong negative split with smooth pace control.** You opened ...
///
/// We render that first bold span as the centerpiece of the share card.
///
/// Fallback chain when the bold span is missing (older feedback rows or
/// a future agent that drops the convention):
///   1. First markdown-bold span (`**...**`).
///   2. First sentence (split on `.`, `!`, `?`).
///   3. The entire trimmed string if it's short enough.
///   4. `null` if the input is null / empty / whitespace.
///
/// Returns trimmed result with no surrounding `**`.
String? extractVerdict(String? aiFeedback) {
  if (aiFeedback == null) return null;
  final raw = aiFeedback.trim();
  if (raw.isEmpty) return null;

  // 1. First **bold** span — agent's intended verdict shape.
  final bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true).firstMatch(raw);
  if (bold != null) {
    final inner = bold.group(1)?.trim();
    if (inner != null && inner.isNotEmpty) return inner;
  }

  // 2. First sentence — split on terminal punctuation.
  final sentenceMatch =
      RegExp(r'^([^.!?]+[.!?])', dotAll: true).firstMatch(raw);
  if (sentenceMatch != null) {
    final inner = sentenceMatch.group(1)?.trim();
    if (inner != null && inner.isNotEmpty) {
      // Strip trailing punctuation so it composes with the card layout.
      return inner.replaceFirst(RegExp(r'[.!?]+$'), '').trim();
    }
  }

  // 3. Short enough to use whole.
  if (raw.length <= 120) return raw;

  // 4. Give up — caller renders without a verdict.
  return null;
}
