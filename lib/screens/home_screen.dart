import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';
import 'create_answer_key_screen.dart';
import 'active_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back! 👋',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'GradeScan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.assignment_turned_in,
                      value: '${appState.scanResults.length}',
                      label: 'Total Scans',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.key,
                      value: '${appState.answerKeys.length}',
                      label: 'Answer Keys',
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.trending_up,
                      value: _getAverageScore(),
                      label: 'Avg Score',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.star,
                      value: _getHighestScore(),
                      label: 'Highest',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'New Answer Key',
                      color: const Color(0xFF2563EB),
                      onTap: () => _showCreateAnswerKeySheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'Start Scanning',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        if (appState.answerKeys.isEmpty) {
                          _showSnackBar(
                            context,
                            'Please create an answer key first',
                          );
                        } else {
                          _showSelectAnswerKeySheet(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.file_download_outlined,
                      title: 'Export Results',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _showExportDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.list_alt,
                      title: 'View All Keys',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showAnswerKeysSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Scans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (appState.scanResults.isNotEmpty)
                    TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ),
              const SizedBox(height: 12),
              if (appState.scanResults.isEmpty)
                const EmptyState(
                  icon: Icons.document_scanner_outlined,
                  title: 'No scans yet',
                  subtitle: 'Start scanning answer sheets to see results here',
                )
              else
                ...appState.scanResults
                    .take(5)
                    .map((result) => RecentScanCard(result: result)),
            ],
          ),
        ),
      ),
    );
  }

  String _getAverageScore() {
    if (appState.scanResults.isEmpty) return '0%';
    final avg =
        appState.scanResults.map((r) => r.percentage).reduce((a, b) => a + b) /
        appState.scanResults.length;
    return '${avg.toStringAsFixed(0)}%';
  }

  String _getHighestScore() {
    if (appState.scanResults.isEmpty) return '0%';
    final highest = appState.scanResults
        .map((r) => r.percentage)
        .reduce((a, b) => a > b ? a : b);
    return '${highest.toStringAsFixed(0)}%';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCreateAnswerKeySheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAnswerKeyScreen()),
    );
  }

  void _showSelectAnswerKeySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SelectAnswerKeySheet(
        onSelect: (key) {
          appState.selectAnswerKey(key);
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveScanScreen(answerKey: key),
            ),
          );
        },
      ),
    );
  }

  void _showAnswerKeysSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            AnswerKeysListSheet(scrollController: scrollController),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    if (appState.scanResults.isEmpty) {
      _showSnackBar(context, 'No results to export');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Color(0xFF10B981)),
              ),
              title: const Text('Export as Excel'),
              subtitle: const Text('.xlsx format'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(
                  context,
                  'Exported ${appState.scanResults.length} results to Excel',
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('.pdf format'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(
                  context,
                  'Exported ${appState.scanResults.length} results to PDF',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
