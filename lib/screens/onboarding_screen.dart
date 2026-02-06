import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Bienvenue à la Maison',
      'subtitle': 'Le Centre de Réveil où chaque vie reçoit le souffle de l\'Esprit.',
    },
    {
      'title': 'Un Suivi d\'Excellence',
      'subtitle': 'Enregistrez et accompagnez chaque nouveau venu dans sa croissance spirituelle.',
    },
    {
      'title': 'Prêt pour le Réveil ?',
      'subtitle': '', // Not used for slide 3 based on custom layout, but good to have struct
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSeConnecter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Méthode _onCreerCompte supprimée - création de compte réservée aux admins

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF0F4F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Logo (Static on top)
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const Spacer(flex: 1),
              
              // Carousel
              Expanded(
                flex: 10,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(index);
                  },
                ),
              ),
              
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildDot(index),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(int index) {
    final data = _slides[index];
    final isLastSlide = index == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B365D), // Zoe Blue probably, assuming dark blue
            ),
          ),
          const SizedBox(height: 16),
          if (!isLastSlide)
            Text(
              data['subtitle']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            
          if (isLastSlide) ...[
             const SizedBox(height: 32),
             // Bouton Se Connecter
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _onSeConnecter,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFB41E3A), // Rouge Cardinal
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                   elevation: 2,
                 ),
                 child: Text(
                   'Se connecter',
                   style: GoogleFonts.inter(
                     fontSize: 16, 
                     fontWeight: FontWeight.bold
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 16),
             // Bouton Créer un compte supprimé (réservé admin)
          ]
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFB41E3A) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
