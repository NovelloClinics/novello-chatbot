import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA3x3UtZU81YewlstOr1jlpF2PTYVxvkFA",
      authDomain: "nifty-expanse-393415.firebaseapp.com",
      projectId: "nifty-expanse-393415",
      storageBucket: "nifty-expanse-393415.appspot.com",
      messagingSenderId: "452020929040",
      appId: "1:452020929040:web:022c4e940ce10b41000095",
    ),
  );
  runApp(const NovelloChatbotApp());
}

class NovelloChatbotApp extends StatelessWidget {
  const NovelloChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novello Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFA0144F),
        scaffoldBackgroundColor: Color(0xFFFFF5F8),
        fontFamily: 'Arial',
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> chatMessages = [];
  late bool isArabic;
  String complaintStep = '';
  Map<String, String> complaintData = {};

  @override
  void initState() {
    super.initState();
    isArabic = ui.window.locale.languageCode == 'ar';
    final welcome = isArabic
        ? "أهلًا بك في نوفيلو! كيف يمكنني مساعدتك؟"
        : "Welcome to Novello! How can I help you?";
    chatMessages.add({"text": welcome, "sender": "bot"});
    Future.delayed(Duration(milliseconds: 800), _addQuickReplies);
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      chatMessages.add({"text": message, "sender": "user"});
    });

    _controller.clear();

    if (complaintStep.isNotEmpty) {
      await _handleComplaintFlow(message);
    } else {
      await FirebaseFirestore.instance.collection('messages').add({
        'text': message,
        'sender': 'user',
        'timestamp': FieldValue.serverTimestamp(),
        'language': isArabic ? 'ar' : 'en',
      });
    }
  }

  Future<void> _handleComplaintFlow(String message) async {
    if (complaintStep == 'type') {
      complaintData['type'] = message;
      complaintStep = 'details';
      _addBotMessage(isArabic ? "من فضلك اكتب تفاصيل الشكوى باختصار" : "Please describe your complaint briefly");
    } else if (complaintStep == 'details') {
      complaintData['details'] = message;
      complaintStep = 'phone';
      _addBotMessage(isArabic ? "ما رقم جوالك للتواصل؟" : "What is your phone number?");
    } else if (complaintStep == 'phone') {
      complaintData['phone'] = message;
      complaintStep = '';

      await FirebaseFirestore.instance.collection('complaints').add({
        'type': complaintData['type'],
        'details': complaintData['details'],
        'phone': complaintData['phone'],
        'timestamp': FieldValue.serverTimestamp(),
        'language': isArabic ? 'ar' : 'en',
      });

      _addBotMessage(isArabic
          ? "شكرًا، تم استلام الشكوى وسنراجعها خلال وقت قصير."
          : "Thank you. Your complaint has been received and will be reviewed shortly.");
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      chatMessages.add({"text": text, "sender": "bot"});
    });
  }

  void _addQuickReplies() {
    final replies = [
      {
        "label": isArabic ? "🎁 العروض" : "🎁 Offers",
        "url": "https://novelloclinics.com/sa/offers"
      },
      {
        "label": isArabic ? "📅 حجز موعد" : "📅 Book Appointment",
        "url": "https://novelloclinics.com/ar/احجز-موعدك"
      },
      {
        "label": isArabic ? "❗ الشكاوى" : "❗ Complaints",
        "url": null
      },
      {
        "label": "💬 WhatsApp",
        "url": "https://api.whatsapp.com/send/?phone=966555085378"
      }
    ];
    for (var reply in replies) {
      setState(() {
        chatMessages.add({"text": reply["label"], "sender": "bot", "url": reply["url"]});
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg["sender"] == "user";
    final align = isUser
        ? (isArabic ? Alignment.centerRight : Alignment.centerLeft)
        : (isArabic ? Alignment.centerLeft : Alignment.centerRight);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFEA1C72) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: msg["url"] != null
              ? () {
                  if (msg["text"].contains("❗")) {
                    setState(() {
                      complaintStep = 'type';
                    });
                    _addBotMessage(isArabic
                        ? "من فضلك اختر نوع الشكوى:"
                        : "Please select complaint type:");
                  } else {
                    _launchURL(msg["url"]);
                  }
                }
              : null,
          child: Text(
            msg["text"],
            style: TextStyle(
              fontSize: 16,
              color: isUser ? Colors.white : Colors.black87,
              decoration: msg["url"] != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    // Stub for launch functionality, needs url_launcher in real project
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFA0144F),
          title: const Text('Novello Chatbot', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                children: chatMessages.reversed.map(_buildMessage).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isArabic ? "اكتب رسالتك..." : "Type your message...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendMessage(_controller.text),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      backgroundColor: const Color(0xFFA0144F),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}