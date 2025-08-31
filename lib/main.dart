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
  // Mode: null = normal, 'edit' = editing, 'delete' = deleting
  String? _actionMode;

  void _startActionMode(String mode) {
    setState(() {
      _actionMode = mode;
    });
  }

  void _exitActionMode() {
    setState(() {
      _actionMode = null;
    });
  }

  void _deleteLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
    _saveLinks();
    _exitActionMode();
  }

  void _editLink(int index) {
    final entry = _links[index];
    _showAddLinkDialog(
      initial: entry,
      onSave: (updated) {
        setState(() {
          _links[index] = updated;
        });
        _saveLinks();
        _exitActionMode();
      },
    );
  }
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

  void _showAddLinkDialog({LinkEntry? initial, void Function(LinkEntry)? onSave}) {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final urlController = TextEditingController(text: initial?.url ?? '');
    Color backgroundColor = initial?.backgroundColor ?? Colors.blue;
    Color foregroundColor = initial?.foregroundColor ?? Colors.white;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(initial == null ? 'Add New Link' : 'Edit Link'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Button Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'URL'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'URL cannot be empty';
                          }
                          final regExp = RegExp(r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/\S*)?$');
                          if (!regExp.hasMatch(value.trim())) {
                            return 'Enter a valid URL';
                          }
                          return null;
                        },
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
                                setState(() {
                                  backgroundColor = picked;
                                });
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
                                setState(() {
                                  foregroundColor = picked;
                                });
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newEntry = LinkEntry(
                        name: nameController.text,
                        url: urlController.text,
                        backgroundColor: backgroundColor,
                        foregroundColor: foregroundColor,
                      );
                      if (onSave != null) {
                        onSave(newEntry);
                      } else {
                        _addLink(newEntry);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(initial == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
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
                  ..._links.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final link = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_actionMode == 'delete') {
                            _deleteLink(idx);
                          } else if (_actionMode == 'edit') {
                            _editLink(idx);
                          } else {
                            _launchURL(link.url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: link.backgroundColor,
                          foregroundColor: link.foregroundColor,
                          elevation: 5,
                          side: _actionMode != null
                              ? const BorderSide(color: Colors.red, width: 2)
                              : null,
                        ),
                        child: Text(link.name),
                      ),
                    );
                  }),
                  if (_links.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No links yet. Tap + to add one!'),
                    ),
                  if (_actionMode != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _actionMode == 'edit'
                            ? 'Tap a link to edit it'
                            : 'Tap a link to delete it',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // Add button (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
              child: FloatingActionButton(
                onPressed: () => _showAddLinkDialog(),
                child: const Icon(Icons.add),
              ),
            ),
          ),
          // Edit/Delete menu (bottom left)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'edit',
                    mini: true,
                    backgroundColor: _actionMode == 'edit' ? Colors.orange : null,
                    onPressed: () {
                      if (_actionMode == 'edit') {
                        _exitActionMode();
                      } else {
                        _startActionMode('edit');
                      }
                    },
                    child: const Icon(Icons.edit),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'delete',
                    mini: true,
                    backgroundColor: _actionMode == 'delete' ? Colors.red : null,
                    onPressed: () {
                      if (_actionMode == 'delete') {
                        _exitActionMode();
                      } else {
                        _startActionMode('delete');
                      }
                    },
                    child: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
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
