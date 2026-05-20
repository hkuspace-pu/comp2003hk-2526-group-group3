import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void downloadCSV(BuildContext context, String csv) {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';

  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
