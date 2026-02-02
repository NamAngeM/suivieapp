import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../services/notification_service.dart';
import '../services/offline_service.dart';
import '../services/assignment_service.dart';
import '../services/follow_up_service.dart';

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
  final _requetePriereController = TextEditingController(); // Added missing controller
  final _commentaireController = TextEditingController(); // New

  // Form state
  String _sexe = 'Homme';
  String _statutMatrimonial = 'Célibataire';
  String _commentConnu = 'Invitation';
  bool _premiereVisite = true;
  bool _souhaiteEtreRecontacte = true;
  bool _recevoirActualites = true;
  
  // New fields state
  bool _baptise = false;
  bool _souhaiteRejoindreGroupe = false;
  int _noteExperience = 3;
  List<String> _pointsForts = [];
  String? _besoinPrioritaire;
  bool _voeuService = false;
  String? _domaineSouhaite;
  
  bool _isLoading = false;
  
  final List<String> _sourcesOptions = [
    'Invitation',
    'Réseaux Sociaux',
    'Passant',
    'TV / Radio',
    'Autre',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _quartierController.dispose();
    _emailController.dispose();
    _requetePriereController.dispose();
    _commentaireController.dispose();
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
        // New fields
        baptise: _baptise,
        souhaiteRejoindreGroupe: _souhaiteRejoindreGroupe,
        noteExperience: _noteExperience,
        pointsForts: _pointsForts,
        commentaireLibre: _commentaireController.text.trim().isNotEmpty ? _commentaireController.text.trim() : null,
        besoinPrioritaire: _besoinPrioritaire,
        voeuService: _voeuService,
        domaineSouhaite: _domaineSouhaite,
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
        String? assignedMemberId;
        if (visitor.souhaiteEtreRecontacte) {
          final assignmentService = AssignmentService();
          assignedMemberId = await assignmentService.assignVisitor(visitor.copyWith(id: visitorId));
        }

        // Générer les 12 tâches de suivi (4 phases)
        await FollowUpService.generateTasksForVisitor(
          visitor.copyWith(id: visitorId),
          assignedTo: assignedMemberId,
        );
      }
      
      if (mounted) {
        final message = offlineService.isOnline 
            ? 'Visiteur enregistré avec succès !'
            : 'Visiteur enregistré (synchronisation en attente)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: offlineService.isOnline 
                ? AppTheme.zoeBlue 
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
    _commentaireController.clear();
    setState(() {
      _sexe = 'Homme';
      _statutMatrimonial = 'Célibataire';
      _commentConnu = 'Invitation';
      _premiereVisite = true;
      _souhaiteEtreRecontacte = true;
      _recevoirActualites = true;
      
      _baptise = false;
      _souhaiteRejoindreGroupe = false;
      _noteExperience = 3;
      _pointsForts = [];
      _besoinPrioritaire = null;
      _voeuService = false;
      _domaineSouhaite = null;
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    
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
                    size: 300,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header Custom
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B365D).withOpacity(0.1),
                            const Color(0xFFB41E3A).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormatted.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bienvenue',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B365D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Remplissez ce formulaire pour chaque nouveau visiteur.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF52606D),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // 🔵 SECTION 1 : Identité & Contact
                          _buildSectionHeader('Identité & Contact', Icons.badge_outlined, const Color(0xFF1B365D)),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _nomController,
                            label: 'NOM COMPLET',
                            hint: 'Ex: JEAN DUPONT',
                            icon: Icons.person_outline,
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer le nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            'SEXE',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildSegmentedChoice('👨 Homme', _sexe == 'Homme', () => setState(() => _sexe = 'Homme'))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSegmentedChoice('👩 Femme', _sexe == 'Femme', () => setState(() => _sexe = 'Femme'))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: _telephoneController,
                            label: 'TÉLÉPHONE WHATSAPP 🇬🇦',
                            hint: '07 08 45 12',
                            prefixText: '+241 ',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Téléphone requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _quartierController,
                            label: 'QUARTIER D\'HABITATION',
                            hint: 'Ex: Akanda, Glass...',
                            icon: Icons.location_on_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Quartier requis';
                                }
                                return null;
                              },
                          ),
                          const SizedBox(height: 20),
                          
                          const Text(
                            'STATUT MATRIMONIAL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Célibataire', 'Marié', 'Fiancé', 'Veuf'].map((status) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildChoiceChip(status, _statutMatrimonial == status, () => setState(() => _statutMatrimonial = status)),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // 🔴 SECTION 2 : Profil & Première Visite
                          _buildSectionHeader('Profil & Première Visite', Icons.accessibility_new, const Color(0xFFB41E3A)),
                          const SizedBox(height: 16),
                          
                          _buildDropdownField(
                            label: 'SOURCE D\'INVITATION',
                            value: _commentConnu,
                            items: _sourcesOptions,
                            onChanged: (val) => setState(() => _commentConnu = val ?? _sourcesOptions[0]),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildToggleRow('Première visite ?', _premiereVisite, (val) => setState(() => _premiereVisite = val)),
                          const Divider(height: 24),
                          _buildToggleRow('Déjà baptisé(e) ?', _baptise, (val) => setState(() => _baptise = val)),
                          const Divider(height: 24),
                          _buildSwitchTile('Souhaite rejoindre un Groupe de Maison', _souhaiteRejoindreGroupe, (val) => setState(() => _souhaiteRejoindreGroupe = val)),
                          const SizedBox(height: 32),
                          
                          // ✨ SECTION 3 : Appréciation du Culte
                          _buildSectionHeader('Appréciation du Culte', Icons.star_outline, Colors.amber[800]!),
                          const SizedBox(height: 16),
                          
                          const Text('NOTE DE L\'EXPÉRIENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEmojiRating(1, '😞', _noteExperience),
                              _buildEmojiRating(2, '😐', _noteExperience),
                              _buildEmojiRating(3, '🙂', _noteExperience),
                              _buildEmojiRating(4, '😍', _noteExperience),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          const Text('POINTS FORTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Louange', 'Prédication', 'Accueil', 'Ambiance'].map((tag) {
                              final isSelected = _pointsForts.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _pointsForts.add(tag);
                                    } else {
                                      _pointsForts.remove(tag);
                                    }
                                  });
                                },
                                selectedColor: Colors.amber[100],
                                checkmarkColor: Colors.amber[900],
                                labelStyle: TextStyle(color: isSelected ? Colors.amber[900] : Colors.black87),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _commentaireController,
                            label: 'COMMENTAIRE LIBRE',
                            hint: 'Une remarque ?',
                            maxLines: 2,
                            icon: Icons.comment_outlined,
                          ),
                          const SizedBox(height: 32),
                          
                          // 🔥 SECTION 4 : Aspirations & Besoins
                          _buildSectionHeader('Aspirations & Besoins', Icons.local_fire_department_outlined, Colors.deepOrange),
                          const SizedBox(height: 16),
                          
                          _buildDropdownField(
                            label: 'BESOIN PRIORITAIRE',
                            value: _besoinPrioritaire,
                            hint: 'Sélectionner un besoin...',
                            items: ['Salut / Baptême', 'Guérison', 'Paix intérieure', 'Enseignement', 'Famille', 'Autre'],
                            onChanged: (val) => setState(() => _besoinPrioritaire = val),
                          ),
                          const SizedBox(height: 20),
                          
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Je souhaite mettre mes talents au service de Dieu', style: TextStyle(fontWeight: FontWeight.w500)),
                            value: _voeuService,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => _voeuService = val ?? false),
                          ),
                          
                           if (_voeuService) ...[
                             const SizedBox(height: 12),
                             _buildDropdownField(
                               label: 'DOMAINE SOUHAITÉ',
                               value: _domaineSouhaite,
                               hint: 'Choisir un domaine...',
                               items: ['Chorale', 'Accueil', 'Technique', 'Média', 'Sécurité', 'Autre'],
                               onChanged: (val) => setState(() => _domaineSouhaite = val),
                             ),
                           ],
                           const SizedBox(height: 32),
                          
                          // 🙏 SECTION 5 : Accompagnement & Suivi
                          _buildSectionHeader('Accompagnement & Suivi', Icons.handshake_outlined, AppTheme.zoeBlue),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _requetePriereController,
                            label: 'REQUÊTE DE PRIÈRE',
                            hint: 'Sujet précis...',
                            maxLines: 3,
                            icon: Icons.favorite_border,
                          ),
                          const SizedBox(height: 20),
                          
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('J\'accepte d\'être recontacté(e)', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Pour prendre de vos nouvelles'),
                            value: _souhaiteEtreRecontacte,
                            activeThumbColor: AppTheme.zoeBlue,
                            onChanged: (val) => setState(() => _souhaiteEtreRecontacte = val),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.zoeBlue,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: AppTheme.zoeBlue.withOpacity(0.3),
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
                                      'ENREGISTRER LE VISITEUR',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
      ],
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: color.withOpacity(0.2))),
        ],
      ),
    );
  }
  
  Widget _buildSegmentedChoice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.zoeBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.zoeBlue : Colors.grey.shade300),
          boxShadow: selected ? [BoxShadow(color: AppTheme.zoeBlue.withOpacity(0.3), blurRadius: 4)] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmojiRating(int value, String emoji, int groupValue) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => setState(() => _noteExperience = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(selected ? 12 : 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: selected ? 32 : 24),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          children: [
            _buildMinisegment('Non', !value, () => onChanged(false)),
            const SizedBox(width: 8),
            _buildMinisegment('Oui', value, () => onChanged(true)),
          ],
        )
      ],
    );
  }

  Widget _buildMinisegment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.zoeBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.zoeBlue.withOpacity(0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              hint: hint != null ? Text(hint) : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? prefixText, // New argument
    TextCapitalization textCapitalization = TextCapitalization.none, // New argument
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
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
            filled: true,
            fillColor: AppTheme.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.zoeBlue, width: 2),
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
          color: selected ? AppTheme.zoeBlue : AppTheme.backgroundGrey,
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
          activeThumbColor: AppTheme.zoeBlue,
        ),
      ],
    );
  }
}
