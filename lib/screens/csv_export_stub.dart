import 'package:flutter/material.dart';

void downloadCSV(BuildContext context, String csv) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("CSV export only works on Web."),
      duration: Duration(seconds: 2),
    ),
  );
}
