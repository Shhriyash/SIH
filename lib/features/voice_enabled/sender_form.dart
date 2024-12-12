import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SenderDetailsPage extends StatefulWidget {
  final Map<String, String> receiverDetails;

  const SenderDetailsPage({Key? key, required this.receiverDetails})
      : super(key: key);

  @override
  State<SenderDetailsPage> createState() => _SenderDetailsPageState();
}

class _SenderDetailsPageState extends State<SenderDetailsPage> {
  // Controllers for fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _currentRecognizedText = "";

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isHindi = false;

  // Modes
  bool _voiceMode = false; // false = manual mode, true = voice mode

  // Which field is selected for voice input?
  String? _selectedField; // "name", "number", "address", "pincode"

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeTTS();
    _speakInstructions();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.9);
  }

  Future<void> _speakInstructions() async {
    String instructions = _isHindi
        ? "कृपया प्रेषक का विवरण भरें। वॉइस मोड में, एक फ़ील्ड चुनें और माइक्रोफ़ोन बटन से बोलकर विवरण दर्ज करें।"
        : "Please fill the sender's details. In voice mode, select a field and press the microphone button to start and stop recording.";
    await _flutterTts.speak(instructions);
  }

  Future<void> _toggleLanguage() async {
    setState(() {
      _isHindi = !_isHindi;
    });
    if (_isHindi) {
      await _flutterTts.setLanguage("hi-IN");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
    await _speakInstructions();
  }

  Future<void> _toggleRecording() async {
    if (!_voiceMode || _selectedField == null) return;

    if (!_isListening) {
      // Start listening
      bool available = await _speech.initialize(
        onStatus: (status) {},
        onError: (errorNotification) {
          print("Error: $errorNotification");
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _currentRecognizedText = ""; // Clear previous results
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _currentRecognizedText = result.recognizedWords;
          });

          if (result.finalResult) {
            switch (_selectedField) {
              case "name":
                _nameController.text = result.recognizedWords;
                break;
              case "number":
                _numberController.text = result.recognizedWords;
                break;
              case "address":
                _addressController.text = result.recognizedWords;
                break;
              case "pincode":
                _pincodeController.text = result.recognizedWords;
                break;
            }
          }
        });
      } else {
        setState(() {
          _isListening = false;
        });
      }
    } else {
      // Stop listening
      setState(() {
        _isListening = false;
      });
      await _speech.stop();
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !_voiceMode, // If voice mode, disable manual typing
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_voiceMode)
            IconButton(
              icon: Icon(
                _selectedField == fieldKey ? Icons.mic : Icons.mic_none,
                color: _selectedField == fieldKey ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _selectedField = _selectedField == fieldKey ? null : fieldKey;
                });
              },
              tooltip: _isHindi
                  ? "इस फ़ील्ड के लिए वॉइस इनपुट चुनें"
                  : "Select this field for voice input",
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _submitDetails() {
    // Combine receiver and sender details for submission
    Map<String, dynamic> details = {
      "receiver": widget.receiverDetails,
      "sender": {
        "name": _nameController.text,
        "number": _numberController.text,
        "address": _addressController.text,
        "pincode": _pincodeController.text,
      },
    };

    // Show details in Snackbar for demonstration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHindi
              ? "सभी विवरण सफलतापूर्वक सबमिट हो गए।"
              : "All details submitted successfully.",
        ),
      ),
    );

    print(details); // Log details for debugging or API submission
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isHindi ? "प्रेषक विवरण" : "Sender Details",
          style: const TextStyle(fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isHindi
                    ? "कृपया प्रेषक का विवरण भरें"
                    : "Please Fill Sender Details",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildField(
                label: _isHindi ? "नाम" : "Name",
                controller: _nameController,
                fieldKey: "name",
              ),
              _buildField(
                label: _isHindi ? "नंबर" : "Number",
                controller: _numberController,
                fieldKey: "number",
              ),
              _buildField(
                label: _isHindi ? "पता" : "Address",
                controller: _addressController,
                fieldKey: "address",
              ),
              _buildField(
                label: _isHindi ? "पिनकोड" : "Pincode",
                controller: _pincodeController,
                fieldKey: "pincode",
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitDetails,
                child: Text(
                  _isHindi ? "सभी विवरण सबमिट करें" : "Submit All Details",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _voiceMode
          ? FloatingActionButton.extended(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              onPressed: _toggleRecording,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(
                _isListening
                    ? (_isHindi ? "सुनना बंद करें" : "Stop Listening")
                    : (_isHindi ? "सुनना शुरू करें" : "Start Listening"),
              ),
            )
          : null,
    );
  }
}
