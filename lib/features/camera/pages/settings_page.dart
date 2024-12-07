// lib/settings_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String currentEndpoint;

  const SettingsPage({super.key, required this.currentEndpoint});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _endpointController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(text: widget.currentEndpoint);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _saveEndpoint() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_endpoint', _endpointController.text.trim());

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API endpoint updated successfully!')),
      );

      Navigator.of(context).pop(); // Return to the previous screen
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API endpoint cannot be empty.';
    }

    Uri? uri = Uri.tryParse(value.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Please enter a valid URL (http or https).';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _endpointController,
                      decoration: const InputDecoration(
                        labelText: 'API Endpoint',
                        border: OutlineInputBorder(),
                        hintText: 'https://your-api-endpoint.com/upload',
                      ),
                      keyboardType: TextInputType.url,
                      validator: _validateUrl,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveEndpoint,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(50), // Make button full-width
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
