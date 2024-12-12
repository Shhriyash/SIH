import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum InputMode { manual, voice }

class ArticleFormPage extends StatefulWidget {
  const ArticleFormPage({super.key});

  @override
  State<ArticleFormPage> createState() => _ArticleFormPageState();
}

class _ArticleFormPageState extends State<ArticleFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverPincodeController =
      TextEditingController();
  final TextEditingController _receiverPostOfficeController =
      TextEditingController();

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderAddressController =
      TextEditingController();
  final TextEditingController _senderPincodeController =
      TextEditingController();

  bool _isLoading = false;
  bool _receiverPincodeGenerated = false;

  InputMode _inputMode = InputMode.manual;

  final TextEditingController _endpointController =
      TextEditingController(text: "http://your_server_for_pincode:5000");

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverAddressController.dispose();
    _receiverPincodeController.dispose();
    _receiverPostOfficeController.dispose();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _senderPincodeController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _generateReceiverDetails() async {
    if (_receiverAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter receiver address first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${_endpointController.text.trim()}/geocode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"address": _receiverAddressController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _receiverPincodeController.text = data['pincode'] ?? '';
          _receiverPostOfficeController.text =
              data['nearest_post_office']?['name'] ?? '';
          _receiverPincodeGenerated = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch receiver details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating details: $e'),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateSenderPincode() async {
    if (_senderAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter sender address first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${_endpointController.text.trim()}/geocode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"address": _senderAddressController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _senderPincodeController.text = data['pincode'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch sender details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating details: $e'),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildInputModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ChoiceChip(
          label: const Text('Manual Entry'),
          selected: _inputMode == InputMode.manual,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _inputMode = InputMode.manual;
              });
            }
          },
        ),
        ChoiceChip(
          label: const Text('Voice-based Entry'),
          selected: _inputMode == InputMode.voice,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _inputMode = InputMode.voice;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildReceiverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receiver Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _receiverNameController,
          enabled: _inputMode == InputMode.manual,
          decoration: const InputDecoration(
            labelText: 'Receiver Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter receiver name'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _receiverAddressController,
          enabled: _inputMode == InputMode.manual,
          decoration: const InputDecoration(
            labelText: 'Receiver Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter receiver address'
              : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _receiverPincodeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Receiver Pincode',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ||
                      (!_receiverAddressController.text.trim().isNotEmpty)
                  ? null
                  : _generateReceiverDetails,
              child: const Text('Generate'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_receiverPincodeGenerated)
          TextFormField(
            controller: _receiverPostOfficeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Nearest Post Office (Receiver)',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildSenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sender Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _senderNameController,
          enabled: _inputMode == InputMode.manual,
          decoration: const InputDecoration(
            labelText: 'Sender Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter sender name'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _senderAddressController,
          enabled: _inputMode == InputMode.manual,
          decoration: const InputDecoration(
            labelText: 'Sender Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter sender address'
              : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _senderPincodeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Sender Pincode',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ||
                      (!_senderAddressController.text.trim().isNotEmpty)
                  ? null
                  : _generateSenderPincode,
              child: const Text('Generate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsDialog() {
    return AlertDialog(
      title: const Text('Settings'),
      content: TextField(
        controller: _endpointController,
        decoration: const InputDecoration(
          labelText: 'Dynamic URL Endpoint',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildVoiceStartButton() {
    // Since we removed actual voice functionality, this will remain a placeholder.
    if (_inputMode == InputMode.voice) {
      return Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input not implemented.')),
              );
            },
            child: const Text('Start Voice Input'),
          ),
        ],
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dakmadad'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => _buildSettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Article Form',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildInputModeToggle(),
                    const SizedBox(height: 20),
                    _buildReceiverSection(),
                    const SizedBox(height: 30),
                    _buildSenderSection(),
                    _buildVoiceStartButton(),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Form submitted successfully!')),
                            );
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
