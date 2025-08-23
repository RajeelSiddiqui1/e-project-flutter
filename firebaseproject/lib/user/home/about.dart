import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Feature {
  final IconData icon;
  final String text;

  const Feature({required this.icon, required this.text});
}

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

  String get name => '$firstName $lastName';
  String get avatarUrl =>
      'https://avatar.iran.liara.run/username?username=$firstName+$lastName';
}

class AboutController extends GetxController {
  final List<Feature> features = const [
    Feature(
      icon: Icons.book_outlined,
      text: "Browse a comprehensive book catalog",
    ),
    Feature(icon: Icons.security_outlined, text: "Secure user authentication"),
    Feature(
      icon: Icons.person_outline,
      text: "Personalized profiles and wishlists",
    ),
    Feature(
      icon: Icons.local_shipping_outlined,
      text: "Order tracking and history",
    ),
    Feature(
      icon: Icons.star_border_outlined,
      text: "Ratings and reviews from the community",
    ),
  ];

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
}

void main() {
  runApp(const BookHavenApp());
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 15, height: 1.6),
      bodySmall: TextStyle(fontSize: 13),
    ),
  );
}

class BookHavenApp extends StatelessWidget {
  const BookHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BookHaven',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: AboutScreen(),
    );
  }
}

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  final AboutController controller = Get.put(AboutController());

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("BookHaven"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textTheme),
            const SizedBox(height: 32),
            _buildMission(textTheme),
            const SizedBox(height: 32),
            _buildFeaturesSection(textTheme, controller.features),
            const SizedBox(height: 32),
            _buildCreatorsSection(textTheme, controller.creators),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          child: Text("Discover Our Story", style: textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        FadeInUp(
          delay: 100,
          child: Text(
            "Everything you need to know about BookHaven and its creators.",
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildMission(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: 200,
          child: Text("Our Mission", style: textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: 300,
          child: Text(
            "BookHaven is your ultimate destination for discovering books. Our mission is to connect readers with stories that inspire, educate, and entertain, all within an intuitive and seamless mobile experience.",
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(TextTheme textTheme, List<Feature> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: 400,
          child: Text("Key Features", style: textTheme.titleLarge),
        ),
        const SizedBox(height: 20),
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return FadeInUp(
            delay: 500 + (index * 100),
            child: FeatureItem(icon: feature.icon, text: feature.text),
          );
        }),
      ],
    );
  }

  Widget _buildCreatorsSection(TextTheme textTheme, List<Creator> creators) {
    final baseDelay = 500 + (controller.features.length * 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: baseDelay,
          child: Text("Meet the Team", style: textTheme.titleLarge),
        ),
        const SizedBox(height: 20),
        ...creators.asMap().entries.map((entry) {
          final index = entry.key;
          final creator = entry.value;
          return FadeInUp(
            delay: baseDelay + 100 + (index * 100),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: CreatorCard(creator: creator),
            ),
          );
        }),
      ],
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1.5),
            ),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class CreatorCard extends StatefulWidget {
  final Creator creator;

  const CreatorCard({super.key, required this.creator});

  @override
  State<CreatorCard> createState() => _CreatorCardState();
}

class _CreatorCardState extends State<CreatorCard> {
  bool _showAllSkills = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayedSkills = _showAllSkills
        ? widget.creator.skills
        : widget.creator.skills.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.creator.avatarUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.creator.name, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        widget.creator.role,
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow("Email", widget.creator.email, textTheme),
            _buildInfoRow("Age", "${widget.creator.age}", textTheme),
            _buildInfoRow("Semester", widget.creator.semester, textTheme),
            const SizedBox(height: 16),
            Text("Skills", style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: displayedSkills
                  .map(
                    (skill) => Chip(
                      label: Text(skill, style: textTheme.bodySmall),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            if (widget.creator.skills.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllSkills = !_showAllSkills;
                  });
                },
                child: Text(_showAllSkills ? "Show Less" : "Show More"),
              ),
            const SizedBox(height: 16),
            _buildLinkRow("Portfolio", widget.creator.portfolio, textTheme),
            _buildLinkRow("GitHub", widget.creator.github, textTheme),
            _buildLinkRow("LinkedIn", widget.creator.linkedin, textTheme),
            _buildLinkRow("Behance", widget.creator.behance, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeInUp({super.key, required this.child, this.delay = 0});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
