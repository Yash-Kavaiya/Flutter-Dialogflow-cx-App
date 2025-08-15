import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'chatbot_client.dart';
import 'google_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-Mobile Assist Chatbot',
      theme: GoogleColors.googleTheme,
      darkTheme: GoogleColors.googleDarkTheme,
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatClient = ChatbotClient(
    projectId: 'innate-lacing-450600-r5',
    agentId: '9205710f-8722-4ce8-aa01-f895e3c74fa5',
    location: 'us-central1',
  );

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Voice functionality
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";
  
  // Camera functionality
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  
  // File functionality
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _initializeSpeech();
    await _initializeTts();
    await _initializeCamera();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      final response = await _chatClient.sendMessage('user-session-1', message);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      
      // Speak the response
      await _speak(response);
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  // Voice functionality methods
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _chatController.text = _wordsSpoken;
    });
  }

  // File functionality methods
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      
      setState(() {
        _messages.add(ChatMessage(
          text: 'File uploaded: $fileName',
          isUser: true,
          messageType: MessageType.file,
          filePath: file.path,
        ));
      });
      _scrollToBottom();
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Photo captured',
          isUser: true,
          messageType: MessageType.image,
          filePath: photo.path,
        ));
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Image selected',
          isUser: true,
          messageType: MessageType.image,
          filePath: image.path,
        ));
      });
      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GoogleColors.greyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Attachment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GoogleColors.greyVeryDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: GoogleColors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: GoogleColors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'File',
                    color: GoogleColors.yellow,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFile();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Live Stream',
                    color: GoogleColors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showCameraStream();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GoogleColors.greyVeryDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showCameraStream() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Live Camera Stream'),
                  backgroundColor: GoogleColors.blue,
                  foregroundColor: GoogleColors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(
                            color: GoogleColors.blue,
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera),
                        label: const Text('Capture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GoogleColors.blue,
                          foregroundColor: GoogleColors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isRecording = !_isRecording;
                          });
                        },
                        icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                        label: Text(_isRecording ? 'Stop' : 'Record'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? GoogleColors.red : GoogleColors.green,
                          foregroundColor: GoogleColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T-Mobile Assist'),
        backgroundColor: GoogleColors.blue,
        foregroundColor: GoogleColors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircularProgressIndicator(
                          color: GoogleColors.blue,
                          strokeWidth: 2,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'T-Mobile Assistant is typing...',
                          style: TextStyle(
                            color: GoogleColors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: GoogleColors.greyLight,
              boxShadow: [
                BoxShadow(
                  color: GoogleColors.grey.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.attach_file),
                  style: IconButton.styleFrom(
                    backgroundColor: GoogleColors.grey.withValues(alpha: 0.1),
                    foregroundColor: GoogleColors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: GoogleColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _speechEnabled && !_isLoading
                      ? (_isListening ? _stopListening : _startListening)
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening ? GoogleColors.red : GoogleColors.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: GoogleColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: GoogleColors.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: GoogleColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageType { text, image, file, voice }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? filePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.messageType = MessageType.text,
    this.filePath,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: GoogleColors.green,
              child: const Icon(Icons.smart_toy, size: 16, color: GoogleColors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? GoogleColors.blue
                    : GoogleColors.greyLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildMessageContent(message),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: GoogleColors.blue,
              child: const Icon(Icons.person, size: 16, color: GoogleColors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    switch (message.messageType) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.filePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(message.filePath!),
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? GoogleColors.white : GoogleColors.greyVeryDark,
                ),
              ),
            ],
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message.isUser ? GoogleColors.white : GoogleColors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? GoogleColors.white : GoogleColors.greyVeryDark,
                ),
              ),
            ),
          ],
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: message.isUser ? GoogleColors.white : GoogleColors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? GoogleColors.white : GoogleColors.greyVeryDark,
                ),
              ),
            ),
          ],
        );
      case MessageType.text:
      default:
        return Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? GoogleColors.white : GoogleColors.greyVeryDark,
          ),
        );
    }
  }
}
