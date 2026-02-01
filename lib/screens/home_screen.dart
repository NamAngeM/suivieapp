import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/notification_service.dart';
import '../services/offline_service.dart';
import '../services/assignment_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _quartierController = TextEditingController();
  final _emailController = TextEditingController();
  final _requetePriereController = TextEditingController();
  
  // Form state
  String _sexe = 'Homme';
  String _statutMatrimonial = 'Célibataire';
  String _commentConnu = 'Réseaux Sociaux';
  bool _premiereVisite = true;
  bool _souhaiteEtreRecontacte = true;
  bool _recevoirActualites = true;
  
  bool _isLoading = false;
  
  final List<String> _sourcesOptions = [
    'Réseaux Sociaux',
    'Ami/Famille',
    'Passant',
    'Autre',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _quartierController.dispose();
    _emailController.dispose();
    _requetePriereController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final visitor = Visitor(
        id: '',
        nomComplet: _nomController.text.trim(),
        sexe: _sexe,
        telephone: _telephoneController.text.trim(),
        quartier: _quartierController.text.trim(),
        statutMatrimonial: _statutMatrimonial,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        commentConnu: _commentConnu,
        premiereVisite: _premiereVisite,
        requetePriere: _requetePriereController.text.trim().isNotEmpty 
            ? _requetePriereController.text.trim() 
            : null,
        souhaiteEtreRecontacte: _souhaiteEtreRecontacte,
        recevoirActualites: _recevoirActualites,
        dateEnregistrement: DateTime.now(),
      );
      
      // Utiliser le service hors-ligne pour sauvegarder
      final offlineService = OfflineService();
      final visitorId = await offlineService.saveVisitor(visitor);
      
      // Programmer le rappel J+3 pour ce visiteur (seulement si en ligne)
      if (offlineService.isOnline && !visitorId.startsWith('pending_')) {
        final notificationService = NotificationService();
        await notificationService.scheduleJ3Reminder(
          visitorId: visitorId,
          visitorName: visitor.nomComplet,
          registrationDate: visitor.dateEnregistrement,
        );
        
        // Attribuer automatiquement si souhaité
        if (visitor.souhaiteEtreRecontacte) {
          final assignmentService = AssignmentService();
          // On passe une copie du visiteur avec l'ID correct
          await assignmentService.assignVisitor(visitor.copyWith(id: visitorId));
        }
      }
      
      if (mounted) {
        final message = offlineService.isOnline 
            ? 'Visiteur enregistré avec succès !'
            : 'Visiteur enregistré (synchronisation en attente)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: offlineService.isOnline 
                ? AppTheme.accentGreen 
                : AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nomController.clear();
    _telephoneController.clear();
    _quartierController.clear();
    _emailController.clear();
    _requetePriereController.clear();
    setState(() {
      _sexe = 'Homme';
      _statutMatrimonial = 'Célibataire';
      _commentConnu = 'Réseaux Sociaux';
      _premiereVisite = true;
      _souhaiteEtreRecontacte = true;
      _recevoirActualites = true;
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Text(
                dateFormatted.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enregistrez un nouveau membre de la famille.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Section Identité
              _buildSectionTitle('Identité'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nomController,
                label: 'NOM COMPLET',
                hint: 'Ex: Jean Dupont',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Sexe
              const Text(
                'SEXE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceChip('Homme', _sexe == 'Homme', () => setState(() => _sexe = 'Homme')),
                  const SizedBox(width: 12),
                  _buildChoiceChip('Femme', _sexe == 'Femme', () => setState(() => _sexe = 'Femme')),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _telephoneController,
                label: 'TÉLÉPHONE',
                hint: '+225 07 08 45 12',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Section Localisation & Statut
              _buildSectionTitle('Localisation & Statut'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quartierController,
                label: 'QUARTIER',
                hint: 'Sélectionner un quartier',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le quartier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Statut Matrimonial
              const Text(
                'STATUT MATRIMONIAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Célibataire', 'Marié', 'Fiancé', 'Veuf'].map((status) {
                  return _buildChoiceChip(
                    status, 
                    _statutMatrimonial == status,
                    () => setState(() => _statutMatrimonial = status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _emailController,
                label: 'E-MAIL (OPTIONNEL)',
                hint: 'jean.dupont@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              
              // Section Profil Spirituel
              _buildSectionTitle('Profil Spirituel'),
              const SizedBox(height: 16),
              
              // Comment avez-vous connu?
              const Text(
                'COMMENT AVEZ-VOUS CONNU ?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _commentConnu,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _sourcesOptions.map((source) {
                      return DropdownMenuItem(value: source, child: Text(source));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _commentConnu = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Première visite
              _buildSwitchTile(
                'Première visite à l\'Église ?',
                _premiereVisite,
                (value) => setState(() => _premiereVisite = value),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _requetePriereController,
                label: 'REQUÊTE DE PRIÈRE',
                hint: 'En quoi pouvons-nous vous accompagner en prière ?',
                icon: Icons.favorite_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Section Engagement
              _buildSectionTitle('Engagement'),
              const SizedBox(height: 16),
              
              _buildSwitchTile(
                'Je souhaite être recontacté par un responsable cette semaine.',
                _souhaiteEtreRecontacte,
                (value) => setState(() => _souhaiteEtreRecontacte = value),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                'Je souhaite recevoir les actualités de l\'Église sur WhatsApp.',
                _recevoirActualites,
                (value) => setState(() => _recevoirActualites = value),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          'Enregistrer et Envoyer le Message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
            filled: true,
            fillColor: AppTheme.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentGreen : AppTheme.backgroundGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentGreen,
        ),
      ],
    );
  }
}
