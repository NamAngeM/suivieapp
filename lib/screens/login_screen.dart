import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/message_template.dart';
import '../main.dart';
import '../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await FirebaseService.loginWithCode(code);
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigator()),
        );
      } else {
        setState(() {
          _errorMessage = 'Code invalide';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF0F4F8)],
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Icon(
                    Icons.church,
                    size: 350,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onDoubleTap: () async {
                            final templates = [
                              {
                                'title': '1. Accueil (J+0)',
                                'content': 'Bonjour [Nom], quel privilège de vous avoir accueilli aujourd\'hui à ZOÉ CHURCH - Centre de Réveil ! Nous espérons que vous avez passé un moment béni dans la présence de Dieu. Nous sommes là pour vous. Soyez béni(e) ! 👋',
                              },
                              {
                                'title': '2. Premier Contact (J+1)',
                                'content': 'Bonjour [Nom], c\'est [Bénévole] de l\'équipe d\'accueil de ZOÉ CHURCH. Je prenais de vos nouvelles après votre visite de dimanche. Y a-t-il un sujet de prière particulier pour lequel nous pourrions vous accompagner cette semaine ? 🙏',
                              },
                              {
                                'title': '3. Groupe de Maison (J+3)',
                                'content': 'Hello [Nom] ! Saviez-vous que ZOÉ CHURCH se réunit aussi en semaine dans les maisons ? C\'est le meilleur endroit pour créer des amitiés fortes. Il y a un groupe justement dans votre quartier ([Quartier]). Seriez-vous intéressé(e) pour y faire un tour cette semaine ? 🏠',
                              },
                              {
                                'title': '4. Café des Nouveaux (J+7)',
                                'content': 'Bonjour [Nom], nous organisons un moment d\'échange convivial ce dimanche après le culte pour tous nos nouveaux amis. Ce sera l\'occasion de rencontrer les pasteurs et de découvrir la vision \'Centre de Réveil\'. On vous réserve une place ? ☕',
                              },
                              {
                                'title': '5. Classes Affermissement (Mois 1)',
                                'content': 'Cher(e) [Nom], nous lançons un nouveau cycle de \'Fondements de la Foi\'. C\'est une étape clé pour grandir spirituellement et comprendre les bases de la marche avec Christ. Les cours débutent bientôt. Voulez-vous que je vous inscrive ? 📖',
                              },
                              {
                                'title': '6. Découverte des Dons (Mois 2)',
                                'content': 'Bonjour [Nom], nous voyons que vous devenez un membre précieux de la famille ! Dieu vous a donné des talents uniques. Nous organisons un atelier \'Découverte des dons\' pour vous aider à trouver votre place dans nos départements. Prêt(e) à passer à l\'étape suivante ? 🎖️',
                              },
                            ];
                            
                            for (var t in templates) {
                              await FirebaseService.addMessageTemplate(MessageTemplate(
                                id: '',
                                title: t['title']!,
                                content: t['content']!,
                              ));
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Templates initialisés !'))
                              );
                            }
                          },
                          child: const Icon(
                            Icons.church,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ZOE CHURCH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Text(
                          'Visitors',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _codeController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            labelText: 'CODE D\'ACCÈS',
                            labelStyle: const TextStyle(
                              letterSpacing: 1,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.zoeBlue, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                            errorText: _errorMessage,
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.zoeBlue,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppTheme.zoeBlue.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SE CONNECTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Accès réservé à l\'équipe Zoe Church',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
