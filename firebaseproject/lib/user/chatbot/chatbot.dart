import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

// Creator class to hold the data
class Creator {
  final String firstName;
  final String lastName;
  final String email;
  final int age;
  final String semester;
  final List<String> skills;
  final String portfolio;
  final String github;
  final String linkedin;
  final String behance;
  final String role;

  const Creator({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.age,
    required this.semester,
    required this.skills,
    required this.portfolio,
    required this.github,
    required this.linkedin,
    required this.behance,
    required this.role,
  });
}

// List of creators
final List<Creator> creators = const [
  Creator(
    firstName: "Rajeel",
    lastName: "Siddiqui",
    email: "rajeelsiddiqui3@gmail.com",
    age: 19,
    semester: "4th Semester",
    skills: [
      "Nextjs Developer",
      "Mern Stack Developer",
      "Laravel Developer",
      "GenAi Developer",
      "Flutter Developer",
      "django Developer",
    ],
    portfolio: "rajeel-rajeelsiddiqui1s-projects.vercel.app/",
    github: "github.com/RajeelSiddiqui1/",
    linkedin: "www.linkedin.com/in/rajeel-siddiqui-60532529b/",
    behance: "behance.net/rajeelsiddiqui",
    role: "Full Stack Developer & GenAi developer",
  ),
  Creator(
    firstName: "Muhammad",
    lastName: "Huzaifa",
    email: "huzaifaaptech795@gmail.com",
    age: 18,
    semester: "4th Semester",
    skills: [
      "Frontend Developer (React.js)",
      "Graphics Designer",
      "UI/UX Designer",
      "Flutter Developer",
    ],
    portfolio: "huzaifaportfolio1.netlify.app",
    github: "muhammadhuzaifa795",
    linkedin: "linkedin.com/in/muhammad-huzaifa-irfan/",
    behance: "behance.net/huzaifaaptech",
    role: "Frontend & Flutter Developer, UI/UX Designer",
  ),
  Creator(
    firstName: "Rameen",
    lastName: "Kushi",
    email: "rameenkhushi5@gmail.com ",
    age: 17,
    semester: "5th Semester",
    skills: ["Mobile App Developer", "UI/UX Designer", "Product Manager"],
    portfolio: "rameenkushi.design",
    github: "",
    linkedin: "linkedin.com/in/rameen-kushi",
    behance: "behance.net/rameenkushi",
    role: "Mobile Developer & Product Designer",
  ),
];


class ChatBotFloating extends StatefulWidget {
  const ChatBotFloating({super.key});

  @override
  State<ChatBotFloating> createState() => _ChatBotFloatingState();
}

class _ChatBotFloatingState extends State<ChatBotFloating> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isOpen = false;
  bool _isLoading = false;

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash', // or gemini-1.5-flash
    apiKey: "AIzaSyDXgriO7Uev5FE-KUd1ntCIckO1_ZM35RU",
  );


  String _getCreatorsInfo() {
    final buffer = StringBuffer();
    buffer.writeln("\n--- App Creator Information ---");
    for (var creator in creators) {
      buffer.writeln(
          "Name: ${creator.firstName} ${creator.lastName}, Role: ${creator.role}. Skills: ${creator.skills.join(', ')}. Portfolio: ${creator.portfolio}");
    }
    buffer.writeln(
        "When asked about who made the app, introduce all creators briefly. If asked about a specific person, provide their details.");
    return buffer.toString();
  }

  late final List<Content> _systemPrompt;

  @override
  void initState() {
    super.initState();
    _systemPrompt = [
      Content.text(
        """You are a friendly and helpful assistant for 'Book Heaven'.
Answer only questions related to the user-facing features of Book Heaven.
Book Heaven was created by the idea of Rajeel Siddiqui.
User Features include: user registration/login, browsing the book catalog, managing the cart, using the wishlist, placing orders, and leaving reviews.
Do not mention or answer anything about the admin panel.
Respond in English or Roman Urdu, depending on the user's input language.
Your tone should be helpful and concise. Keep responses clean and in plain text without any special characters or markdown.
If a question is unrelated to the app's user features or its creator, politely state: 'I can only answer questions related to Book Heaven.'

Example Interactions:
User: "How can I add a book in cart?"
Assistant: "To add a book to the cart, simply open the book catalog, select the book you like, and tap the 'Add to Cart' button. You can view all your selected books in the Cart section later."

User: "Wishlist ka use kya hai?"
Assistant: "Wishlist ka feature un books ko save karne ke liye hai jo aap baad me kharidna chahte hain. Isme add ki hui books aapke profile ke wishlist section me save hojati hain."

User: "Cricket ka score kya hai?"
Assistant: "I can only answer questions related to Book Heaven."
"
        
        ${_getCreatorsInfo()}
        """)
    ];
     _messages.add({
      "role": "bot",
      "text": "Hello! How can I help you with the Book Store App today?"
    });
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

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "text": message});
      _isLoading = true;
    });
    _scrollToBottom();
    _controller.clear();

    try {
      final content = [
        ..._systemPrompt,
        Content.text(message),
      ];
      final response = await _model.generateContent(content);
      setState(() {
        _messages.add({
          "role": "bot",
          "text": response.text ?? "Sorry, I couldn't process that."
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "Something went wrong. Please try again."});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Animated Chat Window
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          bottom: _isOpen ? 80 : -500,
          right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isOpen ? 1.0 : 0.0,
            child: Container(
              width: 340,
              height: 450,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _buildChatHeader(theme),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingIndicator(theme);
                          }
                          final msg = _messages[index];
                          final isUserMessage = msg["role"] == "user";
                          return _buildMessageBubble(msg["text"] ?? "", isUserMessage, theme);
                        },
                      ),
                    ),
                    _buildInputField(theme),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Action Button
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isOpen = !_isOpen;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(child: child, scale: animation);
                },
                child: Icon(
                  _isOpen ? Icons.close : Icons.chat_bubble_outline_rounded,
                  key: ValueKey<bool>(_isOpen),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Book Store Assistant",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _isOpen = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUserMessage, ThemeData theme) {
    final bubbleAlignment = isUserMessage ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUserMessage ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer;
    final textColor = isUserMessage ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer;
    final borderRadius = isUserMessage
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: bubbleAlignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
    );
  }

    Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: const SizedBox(
          width: 40,
          height: 20,
          child: Text("...", style: TextStyle(fontSize: 18, letterSpacing: 4), textAlign: TextAlign.center,)
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
         color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _sendMessage,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Ask a question...",
                filled: true,
                fillColor: theme.colorScheme.surface.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
             color: theme.colorScheme.primary,
             borderRadius: BorderRadius.circular(30),
             child: InkWell(
               borderRadius: BorderRadius.circular(30),
               onTap: () => _sendMessage(_controller.text),
               child: Container(
                 padding: const EdgeInsets.all(12),
                 child: Icon(
                   Icons.send,
                   color: theme.colorScheme.onPrimary,
                   size: 22,
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }
}