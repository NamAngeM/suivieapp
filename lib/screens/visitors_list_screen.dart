import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../models/visitor.dart';
import '../services/firebase_service.dart';
import 'visitor_details_screen.dart';

class VisitorsListScreen extends StatefulWidget {
  const VisitorsListScreen({super.key});

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
  final List<String> _quartiers = ['Soa', 'Mimboman', 'Essos', 'Biyem-Assi', 'Autre']; // TODO: Dynamique
  final List<String> _statuts = ['nouveau', 'membre', 'visiteur_regulier'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visiteurs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Rechercher (Nom, Tél...)',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune),
                          color: Colors.grey[600],
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredVisitors.length,
                    itemBuilder: (context, index) {
                      final visitor = filteredVisitors[index];
                      return _VisitorCard(
                        visitor: visitor,
                        onWhatsApp: () => _openWhatsApp(visitor.telephone),
                        onCall: () => _makeCall(visitor.telephone),
                        onDetails: () => _showVisitorDetails(visitor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/');
        },
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
                      color: _selectedStatut == s ? AppTheme.accentGreen : Colors.black,
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
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onDetails;

  const _VisitorCard({
    required this.visitor,
    required this.onWhatsApp,
    required this.onCall,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM.', 'fr_FR').format(visitor.dateEnregistrement);
    final avatarColor = AppTheme.getAvatarColor(visitor.nomComplet);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
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
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          visitor.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: visitor.statut == 'nouveau' 
                                ? AppTheme.accentGreen 
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: AppTheme.accentGreen,
                onTap: onWhatsApp,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.phone_outlined,
                label: 'Appeler',
                color: AppTheme.textSecondary,
                onTap: onCall,
              ),
              const SizedBox(width: 8),
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

