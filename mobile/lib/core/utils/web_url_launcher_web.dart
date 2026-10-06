// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openWebWindow(String url) {
  try {
    final win = html.window.open(url, '_blank');
    if (win == null) {
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..rel = 'noopener noreferrer';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    }
  } catch (_) {
    try {
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..rel = 'noopener noreferrer';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {}
  }
}
