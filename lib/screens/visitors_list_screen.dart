import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';
import '../models/interaction.dart';
import 'visitor_details_screen.dart';
import '../widgets/whatsapp_template_sheet.dart';
import '../models/team_member.dart';
import 'edit_visitor_screen.dart';

class VisitorsListScreen extends StatefulWidget {
  final VoidCallback? onAddVisitor;
  
  const VisitorsListScreen({super.key, this.onAddVisitor});

  @override
  State<VisitorsListScreen> createState() => _VisitorsListScreenState();
}

class _VisitorsListScreenState extends State<VisitorsListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // Filters
  String? _selectedQuartier;
  String? _selectedStatut;
  DateTimeRange? _selectedDateRange;
  final List<String> _quartiers = ['Angondjé', 'Akanda', 'Nzeng Ayong', 'Okala', 'PK8', 'Charbonnages'];
  final List<String> _statuts = ['nouveau', 'contacte', 'fidele'];
  
  Map<String, String> _memberNames = {};
  
  final _whatsappService = WhatsappService();

  @override
  void initState() {
    super.initState();
    _loadMemberNames();
  }

  Future<void> _loadMemberNames() async {
    FirebaseService.getTeamStream().listen((members) {
      if (mounted) {
        setState(() {
          _memberNames = {for (var m in members) m.id: m.nom};
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(Visitor visitor) async {
    await _whatsappService.openWhatsApp(visitor.telephone, '');
  }

  Future<void> _makeCall(Visitor visitor) async {
    final url = Uri.parse('tel:${visitor.telephone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      FirebaseService.addInteraction(Interaction(
        id: '',
        visitorId: visitor.id,
        type: 'call',
        content: 'Appel lancé depuis la liste',
        date: DateTime.now(),
        authorId: FirebaseService.currentUser?.id ?? 'current_user',
        authorName: FirebaseService.currentUser?.nom ?? 'Moi',
      ));
    }
  }

  Future<void> _sendSMS(String phone, String visitorId) async {
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      FirebaseService.addInteraction(Interaction(
        id: '',
        visitorId: visitorId,
        type: 'sms',
        content: 'SMS lancé depuis la liste',
        date: DateTime.now(),
        authorId: FirebaseService.currentUser?.id ?? 'current_user',
        authorName: FirebaseService.currentUser?.nom ?? 'Moi',
      ));
    }
  }

  void _showVisitorDetails(Visitor visitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitorDetailsScreen(visitor: visitor),
      ),
    );
  }

  Future<void> _confirmDeleteVisitor(Visitor visitor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le visiteur ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${visitor.nomComplet} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.deleteVisitor(visitor.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visiteur supprimé')),
        );
      }
    }
  }

  void _editVisitor(Visitor visitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVisitorScreen(visitor: visitor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for gradient
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Text(
                          'Visiteurs',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B365D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher (Nom, Tél...)',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFFB41E3A)),
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.zoeBlue, width: 0.5),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.tune),
                                color: AppTheme.zoeBlue,
                                onPressed: () {
                                  _showFilterSheet();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  // Quick Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Première visite'),
                            selected: _selectedStatut == 'nouveau',
                            onSelected: (selected) {
                              setState(() => _selectedStatut = selected ? 'nouveau' : null);
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF1B365D).withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _selectedStatut == 'nouveau' ? AppTheme.zoeBlue : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _selectedStatut == 'nouveau' ? AppTheme.zoeBlue : Colors.grey.shade200,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_quartiers.isNotEmpty)
                             FilterChip(
                              label: Text(_quartiers.first),
                              selected: _selectedQuartier == _quartiers.first,
                              onSelected: (selected) {
                                setState(() => _selectedQuartier = selected ? _quartiers.first : null);
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: _selectedQuartier == _quartiers.first ? AppTheme.primaryColor : AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _selectedQuartier == _quartiers.first ? AppTheme.primaryColor : Colors.grey.shade200,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // List
                  Expanded(
                    child: StreamBuilder<List<Visitor>>(
                      stream: FirebaseService.getVisitorsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Erreur: ${snapshot.error}'),
                              ],
                            ),
                          );
                        }
                        
                        final visitors = snapshot.data ?? [];
                        final filteredVisitors = visitors.where((v) {
                          bool matchesSearch = true;
                          if (_searchQuery.isNotEmpty) {
                            final query = _searchQuery.toLowerCase();
                            matchesSearch = v.nomComplet.toLowerCase().contains(query) ||
                                   v.quartier.toLowerCase().contains(query) ||
                                   v.telephone.contains(query);
                          }

                          bool matchesQuartier = _selectedQuartier == null || v.quartier == _selectedQuartier;
                          bool matchesStatut = _selectedStatut == null || v.statut == _selectedStatut;
                          
                          bool matchesDate = true;
                          if (_selectedDateRange != null) {
                            matchesDate = v.dateEnregistrement.isAfter(_selectedDateRange!.start) &&
                                v.dateEnregistrement.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                          }

                          return matchesSearch && matchesQuartier && matchesStatut && matchesDate;
                        }).toList();
                        
                        if (filteredVisitors.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Aucun visiteur enregistré' 
                                      : 'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: filteredVisitors.length,
                          itemBuilder: (context, index) {
                            final visitor = filteredVisitors[index];
                            return _VisitorCard(
                              visitor: visitor,
                              assignedMemberName: visitor.assignedMemberId != null 
                                  ? _memberNames[visitor.assignedMemberId] 
                                  : null,
                              onWhatsApp: () => _openWhatsApp(visitor),
                              onCall: () => _makeCall(visitor),
                              onSMS: () => _sendSMS(visitor.telephone, visitor.id),
                              onDetails: () => _showVisitorDetails(visitor),
                              onEdit: () => _editVisitor(visitor),
                              onDelete: () => _confirmDeleteVisitor(visitor),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddVisitor ?? () => Navigator.pushNamed(context, '/'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedQuartier = null;
                          _selectedStatut = null;
                          _selectedDateRange = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Quartier
                const Text('Quartier', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _quartiers.map((q) => ChoiceChip(
                    label: Text(q),
                    selected: _selectedQuartier == q,
                    onSelected: (selected) {
                      setStateSheet(() => _selectedQuartier = selected ? q : null);
                      setState(() {});
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _selectedQuartier == q ? AppTheme.primaryColor : Colors.black,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                // Statut
                const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _statuts.map((s) => ChoiceChip(
                    label: Text(s),
                    selected: _selectedStatut == s,
                    onSelected: (selected) {
                      setStateSheet(() => _selectedStatut = selected ? s : null);
                      setState(() {});
                    },
                    selectedColor: AppTheme.accentGreen.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _selectedStatut == s ? AppTheme.zoeBlue : Colors.black,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Période', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  subtitle: Text(
                    _selectedDateRange == null 
                        ? 'Toute la période' 
                        : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setStateSheet(() => _selectedDateRange = picked);
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Appliquer les filtres', style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final String? assignedMemberName;
  final VoidCallback onWhatsApp;
  final VoidCallback onSMS;
  final VoidCallback onCall;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisitorCard({
    required this.visitor,
    this.assignedMemberName,
    required this.onWhatsApp,
    required this.onSMS,
    required this.onCall,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM.', 'fr_FR').format(visitor.dateEnregistrement);
    final avatarColor = AppTheme.getAvatarColor(visitor.nomComplet);
    
    // Calcul progression
    final totalSteps = visitor.integrationPath.length;
    final completedSteps = visitor.integrationPath.where((s) => s.status.name == 'completed').length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar avec Indicateur de Progression
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54, 
                    height: 54,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade100,
                      color: AppTheme.zoeBlue,
                      strokeWidth: 3,
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        visitor.initials,
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visitor.nomComplet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: visitor.statut == 'nouveau' 
                                ? AppTheme.zoeBlue 
                                : AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${visitor.quartier} · $dateFormatted',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (assignedMemberName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: AppTheme.zoeBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Assigné à : $assignedMemberName',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.zoeBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Menu Options
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: AppTheme.zoeBlue),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: AppTheme.zoeBlue,
                onTap: onWhatsApp,
              ),
              _ActionButton(
                icon: Icons.sms_outlined,
                label: 'SMS',
                color: Colors.blue,
                onTap: onSMS,
              ),
              _ActionButton(
                icon: Icons.phone_outlined,
                label: 'Appel',
                color: AppTheme.textSecondary,
                onTap: onCall,
              ),
              _ActionButton(
                icon: Icons.info_outline,
                label: 'Détails',
                color: AppTheme.textSecondary,
                onTap: onDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
