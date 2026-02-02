import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _pdfService = PdfService();
  bool _isGenerating = false;
  
  // Historique simulé (dans une vraie app, on listerait les fichiers locaux)
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    // Simuler un historique pour l'exemple
    setState(() {
      _history = List.generate(3, (index) {
        final date = DateTime.now().subtract(Duration(days: 30 * (index + 1)));
        return DateFormat('MMMM yyyy', 'fr_FR').format(date);
      });
    });
  }

  Future<void> _generateReport({bool isMonthly = true}) async {
    setState(() => _isGenerating = true);
    
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(now);
      
      // 1. Récupérer les données
      final detailedStats = await FirebaseService.getDetailedStatistics(start, end);
      
      // 2. Générer le PDF
      final file = await _pdfService.generateMonthlyReport(
        detailedStats['visitors'],
        detailedStats,
        monthName,
      );
      
      if (mounted) {
        // 3. Proposer d'ouvrir ou partager
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.zoeBlue, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Rapport généré !',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('rapport_$monthName.pdf'),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pdfService.openFile(file);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ouvrir'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pdfService.shareFile(file, 'Rapport $monthName');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
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
                    size: 300,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Custom Header
                  _buildHeader(context, 'Rapports & Exports', 'ANALYTICS'),
                  
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Section Génération
                        const Text(
                          'Générer un rapport',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          title: 'Rapport Mensuel',
                          description: 'Statistiques complètes, graphiques et liste des visiteurs de ce mois.',
                          icon: Icons.calendar_month,
                          color: AppTheme.primaryColor,
                          onTap: () => _generateReport(isMonthly: true),
                          isLoading: _isGenerating,
                        ),
                        const SizedBox(height: 32),
                        
                        // Section Historique
                        const Text(
                          'Historique récent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._history.map((month) => _buildHistoryItem(month)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.zoeBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B365D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
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
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading 
                      ? SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: color)
                        )
                      : Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zoeBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rapport - $title',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
            onPressed: () {
              // Simuler re-téléchargement ou ouverture
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité d\'historique à venir')),
              );
            },
          ),
        ],
      ),
    );
  }
}
