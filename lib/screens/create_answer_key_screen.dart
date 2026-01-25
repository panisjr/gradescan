import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';

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

            // Progress
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

            // Answer Grid
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
