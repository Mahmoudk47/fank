import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'dart:math';

import '../models/custom_button.dart';
import '../widgets/button_card.dart';
import '../widgets/button_dialog.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class ButtonManagerHome extends StatefulWidget {
  const ButtonManagerHome({super.key});

  @override
  State<ButtonManagerHome> createState() => _ButtonManagerHomeState();
}

class _ButtonManagerHomeState extends State<ButtonManagerHome>
    with TickerProviderStateMixin {
  List<CustomButton> buttons = [];
  bool hasUnsavedChanges = false;
  late AnimationController _totalCountAnimationController;
  late Animation<double> _totalCountAnimation;
  final Map<String, ConfettiController> _confettiControllers = {};

  @override
  void initState() {
    super.initState();
    _totalCountAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _totalCountAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _totalCountAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _loadButtons();
  }

  @override
  void dispose() {
    _totalCountAnimationController.dispose();
    for (var controller in _confettiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buttonsJson = prefs.getString('buttons');

    if (buttonsJson != null) {
      final List<dynamic> decodedButtons = jsonDecode(buttonsJson);
      setState(() {
        buttons =
            decodedButtons.map((item) => CustomButton.fromJson(item)).toList();

        // Initialize confetti controllers for each button
        for (var button in buttons) {
          if (!_confettiControllers.containsKey(button.id)) {
            _confettiControllers[button.id] = ConfettiController(
              duration: const Duration(seconds: 2),
            );
          }
        }
      });
    }
  }

  Future<void> _saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedButtons = jsonEncode(
      buttons.map((button) => button.toJson()).toList(),
    );
    await prefs.setString('buttons', encodedButtons);
    setState(() {
      hasUnsavedChanges = false;
      // Reset isEdited flag for all buttons
      buttons =
          buttons.map((button) => button.copyWith(isEdited: false)).toList();
    });
  }

  int get totalCount {
    return buttons.fold(0, (sum, button) => sum + button.count);
  }

  void _decrementButtonCount(int index) {
    if (buttons[index].count > 0) {
      setState(() {
        final updatedButton = buttons[index].copyWith(
          count: buttons[index].count - 1,
          isEdited: true,
        );
        buttons[index] = updatedButton;
        hasUnsavedChanges = true;

        // Play total count animation
        _totalCountAnimationController.reset();
        _totalCountAnimationController.forward();

        // Check if count reached zero to play confetti
        if (updatedButton.count == 0) {
          _confettiControllers[updatedButton.id]?.play();
        }
      });
    }
  }

  void _showButtonDialog({CustomButton? button, int? editIndex}) {
    showDialog(
      context: context,
      builder:
          (context) => ButtonDialog(
            button: button,
            onSave: (newButton) {
              setState(() {
                if (editIndex != null) {
                  // Edit existing button
                  buttons[editIndex] = newButton.copyWith(isEdited: true);
                } else {
                  // Create new button
                  final newButtonWithId = newButton.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                  );
                  buttons.add(newButtonWithId);

                  // Create confetti controller for the new button
                  _confettiControllers[newButtonWithId.id] = ConfettiController(
                    duration: const Duration(seconds: 2),
                  );
                }
                hasUnsavedChanges = true;
              });
            },
            onDelete:
                editIndex != null
                    ? () {
                      setState(() {
                        final buttonId = buttons[editIndex].id;
                        buttons.removeAt(editIndex);
                        hasUnsavedChanges = true;

                        // Dispose of the confetti controller
                        _confettiControllers[buttonId]?.dispose();
                        _confettiControllers.remove(buttonId);
                      });
                      Navigator.of(context).pop();
                    }
                    : null,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // AppBar removed
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Settings and About buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Improved Total Counter Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 16.0,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Count',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ScaleTransition(
                            scale: _totalCountAnimation,
                            child: Text(
                              totalCount.toString(),
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Button Grid
                  Expanded(
                    child:
                        buttons.isEmpty
                            ? const Center(
                              child: Text(
                                'Create your first button to get started!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                            : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: buttons.length,
                              itemBuilder: (context, index) {
                                final button = buttons[index];
                                return ButtonCard(
                                  button: button,
                                  confettiController:
                                      _confettiControllers[button.id]!,
                                  onTap: () => _decrementButtonCount(index),
                                  onLongPress:
                                      () => _showButtonDialog(
                                        button: button,
                                        editIndex: index,
                                      ),
                                );
                              },
                            ),
                  ),

                  // Save Changes Button
                  if (hasUnsavedChanges)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: screenWidth > 600 ? 400 : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveButtons,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showButtonDialog(),
        tooltip: 'Add Button',
        child: const Icon(Icons.add),
      ),
    );
  }
}
