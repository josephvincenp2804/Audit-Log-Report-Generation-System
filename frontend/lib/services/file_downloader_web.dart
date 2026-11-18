// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> downloadFile(List<int> bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);

  return 'Downloaded in browser: $filename';
}

