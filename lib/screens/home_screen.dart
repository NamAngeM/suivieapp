import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../services/notification_service.dart';
import '../services/offline_service.dart';
import '../services/assignment_service.dart';
import '../services/follow_up_service.dart';
import '../widgets/form/section_header.dart';
import '../widgets/form/custom_text_field.dart';
import '../widgets/form/custom_dropdown_field.dart';
import '../widgets/form/choice_widgets.dart';
import '../widgets/form/rating_widgets.dart';

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
                            const Color(0xFF1B365D).withValues(alpha: 0.1),
                            const Color(0xFFB41E3A).withValues(alpha: 0.1),
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
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
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
                          SectionHeader(
                            title: 'Identité & Contact',
                            icon: Icons.badge_outlined,
                            color: const Color(0xFF1B365D),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
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
                              Expanded(
                                child: SegmentedChoice(
                                  label: '👨 Homme',
                                  selected: _sexe == 'Homme',
                                  onTap: () => setState(() => _sexe = 'Homme'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SegmentedChoice(
                                  label: '👩 Femme',
                                  selected: _sexe == 'Femme',
                                  onTap: () => setState(() => _sexe = 'Femme'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          CustomTextField(
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
                          
                          CustomTextField(
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
                                  child: CustomChoiceChip(
                                    label: status,
                                    selected: _statutMatrimonial == status,
                                    onTap: () => setState(() => _statutMatrimonial = status),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // 🔴 SECTION 2 : Profil & Première Visite
                          SectionHeader(
                            title: 'Profil & Première Visite',
                            icon: Icons.accessibility_new,
                            color: const Color(0xFFB41E3A),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomDropdownField(
                            label: 'SOURCE D\'INVITATION',
                            value: _commentConnu,
                            items: _sourcesOptions,
                            onChanged: (val) => setState(() => _commentConnu = val ?? _sourcesOptions[0]),
                          ),
                          const SizedBox(height: 16),
                          
                          ToggleRow(
                            title: 'Première visite ?',
                            value: _premiereVisite,
                            onChanged: (val) => setState(() => _premiereVisite = val),
                          ),
                          const Divider(height: 24),
                          ToggleRow(
                            title: 'Déjà baptisé(e) ?',
                            value: _baptise,
                            onChanged: (val) => setState(() => _baptise = val),
                          ),
                          const Divider(height: 24),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Souhaite rejoindre un Groupe de Maison'),
                            value: _souhaiteRejoindreGroupe,
                            activeColor: AppTheme.zoeBlue,
                            onChanged: (val) => setState(() => _souhaiteRejoindreGroupe = val),
                          ),
                          const SizedBox(height: 32),
                          
                          // ✨ SECTION 3 : Appréciation du Culte
                          SectionHeader(
                            title: 'Appréciation du Culte',
                            icon: Icons.star_outline,
                            color: Colors.amber[800]!,
                          ),
                          const SizedBox(height: 16),
                          
                          const Text('NOTE DE L\'EXPÉRIENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              EmojiRating(value: 1, emoji: '😞', groupValue: _noteExperience, onChanged: (val) => setState(() => _noteExperience = val)),
                              EmojiRating(value: 2, emoji: '😐', groupValue: _noteExperience, onChanged: (val) => setState(() => _noteExperience = val)),
                              EmojiRating(value: 3, emoji: '🙂', groupValue: _noteExperience, onChanged: (val) => setState(() => _noteExperience = val)),
                              EmojiRating(value: 4, emoji: '😍', groupValue: _noteExperience, onChanged: (val) => setState(() => _noteExperience = val)),
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
                          
                          CustomTextField(
                            controller: _commentaireController,
                            label: 'COMMENTAIRE LIBRE',
                            hint: 'Une remarque ?',
                            maxLines: 2,
                            icon: Icons.comment_outlined,
                          ),
                          const SizedBox(height: 32),
                          
                          // 🔥 SECTION 4 : Aspirations & Besoins
                          SectionHeader(
                            title: 'Aspirations & Besoins',
                            icon: Icons.local_fire_department_outlined,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 16),
                          
                          CustomDropdownField(
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
                             CustomDropdownField(
                               label: 'DOMAINE SOUHAITÉ',
                               value: _domaineSouhaite,
                               hint: 'Choisir un domaine...',
                               items: ['Chorale', 'Accueil', 'Technique', 'Média', 'Sécurité', 'Autre'],
                               onChanged: (val) => setState(() => _domaineSouhaite = val),
                             ),
                           ],
                           const SizedBox(height: 32),
                          
                          // 🙏 SECTION 5 : Accompagnement & Suivi
                          SectionHeader(
                            title: 'Accompagnement & Suivi',
                            icon: Icons.handshake_outlined,
                            color: AppTheme.zoeBlue,
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
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
                                shadowColor: AppTheme.zoeBlue.withValues(alpha: 0.3),
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
}
