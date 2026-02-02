
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../services/firebase_service.dart';

class EditVisitorScreen extends StatefulWidget {
  final Visitor visitor;

  const EditVisitorScreen({super.key, required this.visitor});

  @override
  State<EditVisitorScreen> createState() => _EditVisitorScreenState();
}

class _EditVisitorScreenState extends State<EditVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _quartierController;
  late TextEditingController _emailController;
  late TextEditingController _requetePriereController;
  
  // Form state
  late String _sexe;
  late String _statutMatrimonial;
  late String _commentConnu;
  late bool _premiereVisite;
  late bool _souhaiteEtreRecontacte;
  late bool _recevoirActualites;
  
  bool _isLoading = false;
  
  final List<String> _sourcesOptions = [
    'Réseaux Sociaux',
    'Ami/Famille',
    'Passant',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.visitor.nomComplet);
    _telephoneController = TextEditingController(text: widget.visitor.telephone);
    _quartierController = TextEditingController(text: widget.visitor.quartier);
    _emailController = TextEditingController(text: widget.visitor.email ?? '');
    _requetePriereController = TextEditingController(text: widget.visitor.requetePriere ?? '');
    
    _sexe = widget.visitor.sexe;
    _statutMatrimonial = widget.visitor.statutMatrimonial;
    _commentConnu = _sourcesOptions.contains(widget.visitor.commentConnu) 
        ? widget.visitor.commentConnu 
        : 'Autre';
    _premiereVisite = widget.visitor.premiereVisite;
    _souhaiteEtreRecontacte = widget.visitor.souhaiteEtreRecontacte;
    _recevoirActualites = widget.visitor.recevoirActualites;
  }

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
      final updatedVisitor = widget.visitor.copyWith(
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
      );
      
      await FirebaseService.updateVisitor(updatedVisitor);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Visiteur mis à jour avec succès'),
            backgroundColor: AppTheme.zoeBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Modifier le visiteur'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Section Identité
              _buildSectionHeader('Identité', Icons.badge_outlined),
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
              _buildSectionHeader('Localisation & Statut', Icons.location_on_outlined),
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
              _buildSectionHeader('Profil Spirituel', Icons.auto_awesome_outlined),
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
                  border: Border.all(color: AppTheme.zoeBlue.withOpacity(0.15)),
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
              _buildSectionHeader('Engagement', Icons.volunteer_activism_outlined),
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
                          'Mettre à jour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.2))),
        ],
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
          activeColor: AppTheme.zoeBlue,
        ),
      ],
    );
  }
}
