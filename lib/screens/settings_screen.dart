import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _saveAutomatically = false;
  List<Color> _defaultColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.purple,
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedColors = prefs.getStringList('defaultColors');
    
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _saveAutomatically = prefs.getBool('saveAutomatically') ?? false;
      
      if (savedColors != null && savedColors.isNotEmpty) {
        _defaultColors = savedColors.map((colorStr) => 
          Color(int.parse(colorStr))).toList();
      }
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('saveAutomatically', _saveAutomatically);
    
    // Save default colors
    final List<String> colorStrings = 
      _defaultColors.map((color) => color.value.toString()).toList();
    await prefs.setStringList('defaultColors', colorStrings);
  }

  void _showColorPicker(int index) {
    final TextEditingController hexController = TextEditingController(
      text: '#${_defaultColors[index].value.toRadixString(16).substring(2).toUpperCase()}'
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Default Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hexController,
              decoration: InputDecoration(
                labelText: 'Hex Color Code',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _defaultColors[index],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              onChanged: (value) {
                try {
                  final hexCode = value.replaceAll('#', '');
                  if (hexCode.length == 6) {
                    setState(() {
                      _defaultColors[index] = Color(int.parse('FF$hexCode', radix: 16));
                    });
                  }
                } catch (e) {
                  // Invalid hex code, ignore
                }
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
                color: _defaultColors[index],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final hexCode = hexController.text.replaceAll('#', '');
                if (hexCode.length == 6) {
                  setState(() {
                    _defaultColors[index] = Color(int.parse('FF$hexCode', radix: 16));
                    _saveSettings();
                  });
                }
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid color code')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme for the app'),
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  _saveSettings();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This setting will apply on app restart'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Auto Save'),
            subtitle: const Text('Save changes automatically'),
            trailing: Switch(
              value: _saveAutomatically,
              onChanged: (value) {
                setState(() {
                  _saveAutomatically = value;
                  _saveSettings();
                });
              },
            ),
          ),
          const Divider(),
          
          // Default Colors Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default Button Colors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customize the default colors available when creating buttons',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(_defaultColors.length, (index) {
                    return GestureDetector(
                      onTap: () => _showColorPicker(index),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _defaultColors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Color ${index + 1}'),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Note: Some settings may require app restart to take effect.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}