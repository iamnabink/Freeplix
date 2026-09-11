import 'package:flutter/material.dart';

/// Opt-in text selection for a block of copy — a title, a synopsis, a notice.
///
/// Freeplix deliberately does not wrap whole pages in [SelectionArea]: that
/// turns button labels, nav links and chips into selectable text, so a drag
/// across the UI highlights the controls and a click can start a selection
/// instead of firing. Wrap only the prose a reader might want to quote.
///
/// Inside a [SelectableCopy], [SelectionContainer.disabled] carves out any
/// control that sits between paragraphs and must stay unselectable.
class SelectableCopy extends StatelessWidget {
  const SelectableCopy({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(child: child);
}
