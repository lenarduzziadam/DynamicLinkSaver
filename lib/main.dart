import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

// Model for a link entry
class LinkEntry {
  final String name;
  final String url;
  final Color backgroundColor;
  final Color foregroundColor;

  LinkEntry({
    required this.name,
    required this.url,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'backgroundColor': backgroundColor.value,
        'foregroundColor': foregroundColor.value,
      };

  factory LinkEntry.fromJson(Map<String, dynamic> json) => LinkEntry(
        name: json['name'],
        url: json['url'],
        backgroundColor: Color(json['backgroundColor']),
        foregroundColor: Color(json['foregroundColor']),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Link Storer',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  List<LinkEntry> _links = [];

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _saveLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final linkList = _links.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('links', linkList);
  }

  Future<void> _loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final linkList = prefs.getStringList('links') ?? [];
    setState(() {
      _links = linkList.map((e) => LinkEntry.fromJson(jsonDecode(e))).toList();
    });
  }

  void _addLink(LinkEntry entry) {
    setState(() {
      _links.add(entry);
    });
    _saveLinks();
  }

  void _showAddLinkDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    Color backgroundColor = Colors.blue;
    Color foregroundColor = Colors.white;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Link'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Button Name'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Background:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        Color? picked = await showDialog(
                          context: context,
                          builder: (context) => _ColorPickerDialog(initialColor: backgroundColor),
                        );
                        if (picked != null) {
                          backgroundColor = picked;
                          setState(() {});
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        color: backgroundColor,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    ),
                    const Text('Foreground:'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        Color? picked = await showDialog(
                          context: context,
                          builder: (context) => _ColorPickerDialog(initialColor: foregroundColor),
                        );
                        if (picked != null) {
                          foregroundColor = picked;
                          setState(() {});
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        color: foregroundColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  _addLink(LinkEntry(
                    name: nameController.text,
                    url: urlController.text,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                  ));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 76, 170, 175),
        title: const Text('Dynamic Link Storer'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._links.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _launchURL(entry.url),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: entry.backgroundColor,
                            foregroundColor: entry.foregroundColor,
                            elevation: 5,
                          ),
                          child: Text(entry.name),
                        ),
                      )),
                  if (_links.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No links yet. Tap + to add one!'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLinkDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: _color,
          onColorChanged: (color) => setState(() => _color = color),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
