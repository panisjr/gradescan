import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

// Global camera list
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error initializing cameras: ${e.description}');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GradeScanApp());
}

class GradeScanApp extends StatelessWidget {
  const GradeScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GradeScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ==================== MODELS ====================

class AnswerKey {
  final String id;
  final String name;
  final int totalItems;
  final List<String> answers;
  final DateTime createdAt;

  AnswerKey({
    required this.id,
    required this.name,
    required this.totalItems,
    required this.answers,
    required this.createdAt,
  });
}

class Student {
  final String id;
  final String name;
  final String? section;

  Student({required this.id, required this.name, this.section});
}

class ScanResult {
  final String id;
  final String studentName;
  final int score;
  final int totalItems;
  final List<String> studentAnswers;
  final List<String> correctAnswers;
  final DateTime scannedAt;
  final String answerKeyName;
  final String? imagePath;

  ScanResult({
    required this.id,
    required this.studentName,
    required this.score,
    required this.totalItems,
    required this.studentAnswers,
    required this.correctAnswers,
    required this.scannedAt,
    required this.answerKeyName,
    this.imagePath,
  });

  double get percentage => (score / totalItems) * 100;
}

class Exam {
  final String id;
  final String name;
  final AnswerKey answerKey;
  final List<ScanResult> results;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.name,
    required this.answerKey,
    required this.results,
    required this.createdAt,
  });
}

// ==================== APP STATE ====================

class AppState extends ChangeNotifier {
  List<AnswerKey> answerKeys = [];
  List<ScanResult> scanResults = [];
  List<Exam> exams = [];
  AnswerKey? selectedAnswerKey;

  void addAnswerKey(AnswerKey key) {
    answerKeys.add(key);
    notifyListeners();
  }

  void selectAnswerKey(AnswerKey? key) {
    selectedAnswerKey = key;
    notifyListeners();
  }

  void addScanResult(ScanResult result) {
    scanResults.insert(0, result);
    notifyListeners();
  }

  void deleteAnswerKey(String id) {
    answerKeys.removeWhere((key) => key.id == id);
    if (selectedAnswerKey?.id == id) {
      selectedAnswerKey = null;
    }
    notifyListeners();
  }

  void clearResults() {
    scanResults.clear();
    notifyListeners();
  }
}

// Global state instance
final appState = AppState();

// ==================== MAIN NAVIGATION ====================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScanScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2563EB).withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF2563EB)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(
                Icons.document_scanner,
                color: Color(0xFF2563EB),
              ),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: Color(0xFF2563EB)),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF2563EB)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN ====================

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
                    child: _StatCard(
                      icon: Icons.assignment_turned_in,
                      value: '${appState.scanResults.length}',
                      label: 'Total Scans',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
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
                    child: _StatCard(
                      icon: Icons.trending_up,
                      value: _getAverageScore(),
                      label: 'Avg Score',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
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
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'New Answer Key',
                      color: const Color(0xFF2563EB),
                      onTap: () => _showCreateAnswerKeySheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
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
                    child: _QuickActionCard(
                      icon: Icons.file_download_outlined,
                      title: 'Export Results',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _showExportDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
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
                _EmptyState(
                  icon: Icons.document_scanner_outlined,
                  title: 'No scans yet',
                  subtitle: 'Start scanning answer sheets to see results here',
                )
              else
                ...appState.scanResults
                    .take(5)
                    .map((result) => _RecentScanCard(result: result)),
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
      builder: (context) => _SelectAnswerKeySheet(
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
            _AnswerKeysListSheet(scrollController: scrollController),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanResult result;

  const _RecentScanCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.percentage >= 75
        ? const Color(0xFF10B981)
        : result.percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                result.studentName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.answerKeyName} • ${_formatDate(result.scannedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.score}/${result.totalItems}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _SelectAnswerKeySheet extends StatelessWidget {
  final Function(AnswerKey) onSelect;

  const _SelectAnswerKeySheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Answer Key',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...appState.answerKeys.map(
            (key) => ListTile(
              onTap: () => onSelect(key),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key, color: Color(0xFF2563EB)),
              ),
              title: Text(
                key.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${key.totalItems} items'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AnswerKeysListSheet extends StatefulWidget {
  final ScrollController scrollController;

  const _AnswerKeysListSheet({required this.scrollController});

  @override
  State<_AnswerKeysListSheet> createState() => _AnswerKeysListSheetState();
}

class _AnswerKeysListSheetState extends State<_AnswerKeysListSheet> {
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Answer Keys',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAnswerKeyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: appState.answerKeys.isEmpty
                ? Center(
                    child: _EmptyState(
                      icon: Icons.key_outlined,
                      title: 'No answer keys yet',
                      subtitle:
                          'Create your first answer key to start scanning',
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: appState.answerKeys.length,
                    itemBuilder: (context, index) {
                      final key = appState.answerKeys[index];
                      return _AnswerKeyTile(
                        answerKey: key,
                        onDelete: () {
                          appState.deleteAnswerKey(key.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnswerKeyTile extends StatelessWidget {
  final AnswerKey answerKey;
  final VoidCallback onDelete;

  const _AnswerKeyTile({required this.answerKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.key, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answerKey.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${answerKey.totalItems} items • ${_formatAnswers(answerKey.answers)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Answer Key'),
                  content: Text(
                    'Are you sure you want to delete "${answerKey.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatAnswers(List<String> answers) {
    if (answers.length <= 5) return answers.join(', ');
    return '${answers.take(5).join(', ')}...';
  }
}

// ==================== CREATE ANSWER KEY SCREEN ====================

class CreateAnswerKeyScreen extends StatefulWidget {
  const CreateAnswerKeyScreen({super.key});

  @override
  State<CreateAnswerKeyScreen> createState() => _CreateAnswerKeyScreenState();
}

class _CreateAnswerKeyScreenState extends State<CreateAnswerKeyScreen> {
  final _nameController = TextEditingController();
  final _itemsController = TextEditingController(text: '10');
  List<String> _answers = [];
  int _currentItem = 0;
  final List<String> _options = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _initializeAnswers();
  }

  void _initializeAnswers() {
    final count = int.tryParse(_itemsController.text) ?? 10;
    _answers = List.filled(count, '');
    _currentItem = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Create Answer Key'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Input
            const Text(
              'Answer Key Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Math Quiz 1',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Number of Items
            const Text(
              'Number of Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '10',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _initializeAnswers();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          final current =
                              int.tryParse(_itemsController.text) ?? 10;
                          if (current > 1) {
                            _itemsController.text = (current - 1).toString();
                            setState(() => _initializeAnswers());
                          }
                        },
                        icon: const Icon(
                          Icons.remove,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final current =
                              int.tryParse(_itemsController.text) ?? 10;
                          if (current < 100) {
                            _itemsController.text = (current + 1).toString();
                            setState(() => _initializeAnswers());
                          }
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '${_answers.where((a) => a.isNotEmpty).length}/${_answers.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _answers.isEmpty
                          ? 0
                          : _answers.where((a) => a.isNotEmpty).length /
                                _answers.length,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF2563EB),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Answer Input Section
            const Text(
              'Set Answers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),

            // Current Item Selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Item ${_currentItem + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _options.map((option) {
                      final isSelected =
                          _answers.isNotEmpty &&
                          _currentItem < _answers.length &&
                          _answers[_currentItem] == option;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_currentItem < _answers.length) {
                              _answers[_currentItem] = option;
                              if (_currentItem < _answers.length - 1) {
                                _currentItem++;
                              }
                            }
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentItem > 0
                            ? () => setState(() => _currentItem--)
                            : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: _currentItem > 0
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${_currentItem + 1} / ${_answers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: _currentItem < _answers.length - 1
                            ? () => setState(() => _currentItem++)
                            : null,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: _currentItem < _answers.length - 1
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Answer Grid Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Answers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_answers.length, (index) {
                      final hasAnswer = _answers[index].isNotEmpty;
                      final isCurrentItem = index == _currentItem;
                      return GestureDetector(
                        onTap: () => setState(() => _currentItem = index),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCurrentItem
                                ? const Color(0xFF2563EB)
                                : hasAnswer
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrentItem
                                  ? const Color(0xFF2563EB)
                                  : hasAnswer
                                  ? const Color(0xFF10B981)
                                  : Colors.grey[300]!,
                              width: isCurrentItem ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCurrentItem
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                _answers[index].isEmpty ? '-' : _answers[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentItem
                                      ? Colors.white
                                      : hasAnswer
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAnswerKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Answer Key',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveAnswerKey() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the answer key')),
      );
      return;
    }

    if (_answers.any((a) => a.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please set all answers')));
      return;
    }

    final answerKey = AnswerKey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      totalItems: _answers.length,
      answers: List.from(_answers),
      createdAt: DateTime.now(),
    );

    appState.addAnswerKey(answerKey);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Answer key "${answerKey.name}" created successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}

// ==================== SCAN SCREEN ====================

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Scan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Selected Answer Key
            if (appState.selectedAnswerKey != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Answer Key',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            appState.selectedAnswerKey!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showSelectAnswerKeySheet(context),
                      child: const Text(
                        'Change',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Scan Illustration
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(
                        Icons.document_scanner,
                        size: 80,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Ready to Scan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appState.answerKeys.isEmpty
                          ? 'Create an answer key first to start scanning'
                          : appState.selectedAnswerKey == null
                          ? 'Select an answer key to start scanning'
                          : 'Tap the button below to scan an answer sheet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (appState.answerKeys.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAnswerKeyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Answer Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else if (appState.selectedAnswerKey == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSelectAnswerKeySheet(context),
                  icon: const Icon(Icons.key),
                  label: const Text('Select Answer Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveScanScreen(
                          answerKey: appState.selectedAnswerKey!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Start Scanning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSelectAnswerKeySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SelectAnswerKeySheet(
        onSelect: (key) {
          appState.selectAnswerKey(key);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ==================== ACTIVE SCAN SCREEN WITH REAL CAMERA ====================

class ActiveScanScreen extends StatefulWidget {
  final AnswerKey answerKey;

  const ActiveScanScreen({super.key, required this.answerKey});

  @override
  State<ActiveScanScreen> createState() => _ActiveScanScreenState();
}

class _ActiveScanScreenState extends State<ActiveScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _scannedCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isDenied) {
      setState(() {
        _errorMessage = 'Camera permission denied';
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage =
            'Camera permission permanently denied. Please enable it in settings.';
      });
      return;
    }

    if (cameras.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras available';
      });
      return;
    }

    // Select the back camera
    final CameraDescription camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Camera error: ${e.description}';
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Scan Frame Overlay
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isScanning
                          ? Color.lerp(
                              const Color(0xFF2563EB),
                              const Color(0xFF10B981),
                              _animationController.value,
                            )!
                          : Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      Positioned(
                        top: -2,
                        left: -2,
                        child: _CornerIndicator(isScanning: _isScanning),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Transform.rotate(
                          angle: math.pi / 2,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Transform.rotate(
                          angle: math.pi,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        left: -2,
                        child: Transform.rotate(
                          angle: -math.pi / 2,
                          child: _CornerIndicator(isScanning: _isScanning),
                        ),
                      ),
                      // Scanning line
                      if (_isScanning)
                        Positioned(
                          top: 380 * _animationController.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF10B981),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.answerKey.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isCameraInitialized ? _toggleFlash : null,
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? Colors.yellow : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isScanning
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isScanning
                          ? 'Processing...'
                          : 'Align the answer sheet within the frame',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scan Button and Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Scanned Count
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_scannedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scanned',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Scan Button
                      GestureDetector(
                        onTap: (_isScanning || !_isCameraInitialized)
                            ? null
                            : _captureAndProcess,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isScanning || !_isCameraInitialized)
                                ? Colors.grey
                                : const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Icon(
                            _isScanning ? Icons.hourglass_empty : Icons.camera,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      // View Results
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _scannedCount > 0
                                ? () {
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _scannedCount > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isScanning = true);

    try {
      // Capture the image
      final XFile image = await _cameraController!.takePicture();
      debugPrint('Image captured: ${image.path}');

      // TODO: Here you would process the image with OCR/ML
      // For now, we'll simulate the processing
      await Future.delayed(const Duration(seconds: 2));

      // Generate simulated result (replace with actual OCR processing)
      final result = _processImage(image.path);

      appState.addScanResult(result);

      setState(() {
        _isScanning = false;
        _scannedCount++;
      });

      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      setState(() => _isScanning = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      }
    }
  }

  ScanResult _processImage(String imagePath) {
    // TODO: Implement actual OCR processing here
    // For now, generate random results for demonstration
    final random = math.Random();
    final studentNames = [
      'John Doe',
      'Jane Smith',
      'Bob Wilson',
      'Alice Brown',
      'Charlie Davis',
      'Eva Martinez',
      'Frank Johnson',
      'Grace Lee',
    ];

    final studentAnswers = List.generate(
      widget.answerKey.totalItems,
      (index) => ['A', 'B', 'C', 'D'][random.nextInt(4)],
    );

    int score = 0;
    for (int i = 0; i < widget.answerKey.totalItems; i++) {
      if (studentAnswers[i] == widget.answerKey.answers[i]) {
        score++;
      }
    }

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentName: studentNames[random.nextInt(studentNames.length)],
      score: score,
      totalItems: widget.answerKey.totalItems,
      studentAnswers: studentAnswers,
      correctAnswers: widget.answerKey.answers,
      scannedAt: DateTime.now(),
      answerKeyName: widget.answerKey.name,
      imagePath: imagePath,
    );
  }

  void _showResultDialog(ScanResult result) {
    final color = result.percentage >= 75
        ? const Color(0xFF10B981)
        : result.percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.percentage >= 75
                      ? Icons.celebration
                      : result.percentage >= 50
                      ? Icons.thumb_up
                      : Icons.refresh,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.studentName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.score}/${result.totalItems}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${result.percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ResultDetailScreen(result: result),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerIndicator extends StatelessWidget {
  final bool isScanning;

  const _CornerIndicator({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(
          color: isScanning ? const Color(0xFF10B981) : Colors.white,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== RESULT DETAIL SCREEN ====================

class ResultDetailScreen extends StatelessWidget {
  final ScanResult result;

  const ResultDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.percentage >= 75
        ? const Color(0xFF10B981)
        : result.percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Scan Result'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Result shared!')));
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            result.studentName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.studentName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              result.answerKeyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ScoreItem(
                        label: 'Score',
                        value: '${result.score}/${result.totalItems}',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _ScoreItem(
                        label: 'Percentage',
                        value: '${result.percentage.toStringAsFixed(0)}%',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _ScoreItem(label: 'Correct', value: '${result.score}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Answer Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: result.totalItems,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final isCorrect =
                          result.studentAnswers[index] ==
                          result.correctAnswers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Answer: ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    result.studentAnswers[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  if (!isCorrect) ...[
                                    Text(
                                      ' (Correct: ',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      result.correctAnswers[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    Text(
                                      ')',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 24,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}

// ==================== HISTORY SCREEN ====================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('History'),
        actions: [
          if (appState.scanResults.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear History'),
                      content: const Text(
                        'Are you sure you want to clear all scan history?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            appState.clearResults();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'export') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported to Excel!')),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download),
                      SizedBox(width: 8),
                      Text('Export All'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: appState.scanResults.isEmpty
          ? Center(
              child: _EmptyState(
                icon: Icons.history,
                title: 'No scan history',
                subtitle: 'Your scanned results will appear here',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: appState.scanResults.length,
              itemBuilder: (context, index) {
                final result = appState.scanResults[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultDetailScreen(result: result),
                      ),
                    );
                  },
                  child: _RecentScanCard(result: result),
                );
              },
            ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoFlash = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _exportFormat = 'Excel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GradeScan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scanner Settings
            const Text(
              'Scanner Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.flash_on,
                  title: 'Auto Flash',
                  subtitle: 'Automatically turn on flash in low light',
                  trailing: Switch(
                    value: _autoFlash,
                    onChanged: (value) => setState(() => _autoFlash = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Play sound when scanning is complete',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.vibration,
                  title: 'Vibration',
                  subtitle: 'Vibrate on successful scan',
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: (value) =>
                        setState(() => _vibrationEnabled = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Export Settings
            const Text(
              'Export Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.file_copy,
                  title: 'Default Export Format',
                  subtitle: _exportFormat,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Select Export Format',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(
                                Icons.table_chart,
                                color: Color(0xFF10B981),
                              ),
                              title: const Text('Excel (.xlsx)'),
                              trailing: _exportFormat == 'Excel'
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _exportFormat = 'Excel');
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFFEF4444),
                              ),
                              title: const Text('PDF (.pdf)'),
                              trailing: _exportFormat == 'PDF'
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _exportFormat = 'PDF');
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.code,
                                color: Color(0xFF2563EB),
                              ),
                              title: const Text('CSV (.csv)'),
                              trailing: _exportFormat == 'CSV'
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _exportFormat = 'CSV');
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.star_outline,
                  title: 'Rate App',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Made with ❤️ for Educators',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      trailing: trailing,
    );
  }
}
