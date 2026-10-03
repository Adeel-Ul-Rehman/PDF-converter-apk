import 'package:flutter/material.dart';
import 'package:flux_convert/features/files/presentation/pages/files_page.dart';

// IMPROVED: Re-export FilesPage as HistoryPage for backwards compatibility with Shell Scaffold & Router
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FilesPage();
  }
}
