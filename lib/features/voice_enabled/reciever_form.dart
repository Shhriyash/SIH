import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/voice_enabled/sender_form.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MaterialApp(
    home: ReceiverDetailsPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class ReceiverDetailsPage extends StatefulWidget {
  const ReceiverDetailsPage({Key? key}) : super(key: key);

  @override
  State<ReceiverDetailsPage> createState() => _ReceiverDetailsPageState();
}

class _ReceiverDetailsPageState extends State<ReceiverDetailsPage> {
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
        ? "कृपया मोड चुनें: मैन्युअल या वॉइस। वॉइस मोड में, एक फ़ील्ड चुनें और माइक्रोफ़ोन बटन से बोलकर विवरण दर्ज करें।"
        : "Please choose a mode: Manual or Voice. In voice mode, select a field and press the microphone button to start and stop recording. Your spoken words will fill the selected field.";
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
              enabled: !_voiceMode, // Disable manual typing in voice mode
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
                color:
                    _selectedField == fieldKey ? Colors.redAccent : Colors.grey,
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

  void _navigateToSenderDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SenderDetailsPage(
          receiverDetails: {
            "name": _nameController.text,
            "number": _numberController.text,
            "address": _addressController.text,
            "pincode": _pincodeController.text,
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isHindi ? "प्राप्तकर्ता विवरण" : "Receiver Details",
          style: const TextStyle(fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.language_outlined),
            color: Colors.amber,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Center(
                child: Text(
                  _isHindi
                      ? "मोड चुनें: मैन्युअल या वॉइस"
                      : "Choose Mode: Manual or Voice",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: SwitchListTile(
                  activeColor: AppColors.primaryRed,
                  title: Text(
                    _voiceMode
                        ? (_isHindi
                            ? "वॉइस मोड (बोलकर दर्ज)"
                            : "Voice Mode (Speak to Fill)")
                        : (_isHindi
                            ? "मैन्युअल मोड (टाइप करके दर्ज)"
                            : "Manual Mode (Type to Fill)"),
                    style: const TextStyle(fontSize: 18),
                  ),
                  value: _voiceMode,
                  onChanged: (value) {
                    setState(() {
                      _voiceMode = value;
                      _selectedField =
                          null; // Clear field selection when switching modes
                    });
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _navigateToSenderDetails,
                child: Text(
                  _isHindi ? "अगला (प्रेषक विवरण)" : "Next (Sender Details)",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _voiceMode
          ? FloatingActionButton.extended(
              backgroundColor: _isListening ? Colors.red : Colors.amber,
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
