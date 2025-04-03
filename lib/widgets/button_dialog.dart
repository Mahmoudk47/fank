import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_button.dart';

class ButtonDialog extends StatefulWidget {
  final CustomButton? button;
  final Function(CustomButton) onSave;
  final VoidCallback? onDelete;

  const ButtonDialog({
    super.key,
    this.button,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ButtonDialog> createState() => _ButtonDialogState();
}

class _ButtonDialogState extends State<ButtonDialog> {
  late TextEditingController _labelController;
  late TextEditingController _countController;
  late Color _selectedColor;
  bool _useCustomColor = false;
  late TextEditingController _hexColorController;
  late List<Color> _presetColors;

  @override
  void initState() {
    super.initState();
    _loadPresetColors().then((_) {
      _labelController = TextEditingController(text: widget.button?.label ?? '');
      _countController = TextEditingController(
          text: widget.button?.count.toString() ?? '10');
      _selectedColor = widget.button?.color ?? _presetColors[0];
      _hexColorController = TextEditingController(
          text: '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}');
      
      // Check if the color is a custom one
      if (widget.button != null && !_presetColors.contains(widget.button!.color)) {
        _useCustomColor = true;
      }
      setState(() {});
    });
  }

  Future<void> _loadPresetColors() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedColors = prefs.getStringList('defaultColors');
    
    if (savedColors != null && savedColors.isNotEmpty) {
      _presetColors = savedColors.map((colorStr) => 
        Color(int.parse(colorStr))).toList();
    } else {
      // Default colors if none are saved
      _presetColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.amber,
        Colors.purple,
      ];
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _countController.dispose();
    _hexColorController.dispose();
    super.dispose();
  }

  void _updateHexController() {
    _hexColorController.text =
        '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _tryUpdateColorFromHex() {
    try {
      final hexCode = _hexColorController.text.replaceAll('#', '');
      if (hexCode.length == 6) {
        setState(() {
          _selectedColor = Color(int.parse('FF$hexCode', radix: 16));
        });
      }
    } catch (e) {
      // Invalid hex code, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.button != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Button' : 'Create New Button',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Label Field
              const Text(
                'Label',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: 'Enter button label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLength: 20,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              
              // Count Field
              const Text(
                'Count',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _countController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              
              // Color Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Color',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Use custom color'),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _useCustomColor,
                        onChanged: (value) {
                          setState(() {
                            _useCustomColor = value!;
                            if (!_useCustomColor) {
                              _selectedColor = _presetColors[0];
                              _updateHexController();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Preset Colors
              if (!_useCustomColor && _presetColors.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _presetColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _updateHexController();
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (_selectedColor == color)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              // Custom Color Picker
              if (_useCustomColor)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _hexColorController,
                      decoration: InputDecoration(
                        labelText: 'Hex Color Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        _tryUpdateColorFromHex();
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preview:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Dialog Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onDelete != null)
                    ElevatedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_labelController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a label'),
                              ),
                            );
                            return;
                          }
                          
                          final count = int.tryParse(_countController.text) ?? 0;
                          
                          final newButton = CustomButton(
                            id: widget.button?.id ?? '',
                            label: _labelController.text,
                            count: count,
                            color: _selectedColor,
                          );
                          
                          widget.onSave(newButton);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
    );
  }
}