import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';
import 'reports_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _monthlyGoal = 20;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await FirebaseService.getGoal('monthly_visitors');
    if (mounted && goal > 0) {
      setState(() => _monthlyGoal = goal);
    }
  }

  Future<void> _updateGoal() async {
    final controller = TextEditingController(text: _monthlyGoal.toString());
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Objectif Mensuel'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nombre de visiteurs visé',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.zoeBlue.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.zoeBlue.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.zoeBlue, width: 2),
              ),
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) Navigator.pop(context, val);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newGoal != null) {
      await FirebaseService.saveGoal('monthly_visitors', newGoal);
      setState(() => _monthlyGoal = newGoal);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await FirebaseService.getStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
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
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DASHBOARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF52606D),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Statistiques',
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
                          child: RefreshIndicator(
                            onRefresh: _loadStats,
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Text(
                                  'Aperçu de la croissance et de l\'impact.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                    
                                // KPIs Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _KpiCard(
                                        label: 'Total Visiteurs\n(Mois)',
                                        value: '${_stats?['visitorsThisMonth'] ?? 0}',
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _KpiCard(
                                        label: 'Taux de\nRétention',
                                        value: '${_stats?['retentionRate'] ?? 0}%',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _KpiCard(
                                        label: 'Demandes\nPrière',
                                        value: '${_stats?['prayerRequests'] ?? 0}',
                                        color: AppTheme.accentOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Objectifs Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Objectifs',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _updateGoal,
                                      child: const Text('Modifier'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildGoalCard(),
                                const SizedBox(height: 32),
                                
                                // Growth Chart
                                const Text(
                                  'Croissance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nouveaux Visiteurs (12 sem.)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 180,
                                  child: _buildLineChart(),
                                ),
                                const SizedBox(height: 32),
                                
                                // Distribution Section
                                const Text(
                                  'Répartition',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Source distribution
                                const Text(
                                  'Source d\'invitation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildSourceLegend(),
                                const SizedBox(height: 24),
                                
                                // Par Quartier
                                const Text(
                                  'Par Quartier',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: _buildQuartierChart(),
                                ),
                                const SizedBox(height: 32),
                                
                                // Exports
                                const Text(
                                  'Exports',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ReportsScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('Rapports PDF & Exports'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Export en cours...')),
                                      );
                                    },
                                    icon: Icon(Icons.table_chart_outlined, color: Colors.grey[600]),
                                    label: Text(
                                      'Exporter base de données',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
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

  Widget _buildLineChart() {
    final weeklyGrowth = (_stats?['weeklyGrowth'] as List<dynamic>?)
        ?.map((e) => (e as int).toDouble())
        .toList() ?? List.filled(12, 0.0);
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: weeklyGrowth.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLegend() {
    final sources = (_stats?['sourceDistribution'] as Map<String, dynamic>?)?.cast<String, int>() ?? {};
    final total = sources.values.fold<int>(0, (a, b) => a + b);
    
    if (total == 0) {
      return Text('Aucune donnée', style: TextStyle(color: Colors.grey[400]));
    }
    
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentGreen,
      AppTheme.accentOrange,
      Colors.grey,
    ];
    
    int colorIndex = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: sources.entries.map((e) {
        final percentage = (e.value / total * 100).round();
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${e.key} ($percentage%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuartierChart() {
    final quartiers = (_stats?['quartierDistribution'] as Map<String, dynamic>?)?.cast<String, int>() ?? {};
    
    if (quartiers.isEmpty) {
      return Center(
        child: Text('Aucune donnée', style: TextStyle(color: Colors.grey[400])),
      );
    }
    
    final entries = quartiers.entries.take(5).toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((e) {
        final height = maxValue > 0 ? (e.value / maxValue * 80) : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.key.length > 8 ? '${e.key.substring(0, 6)}...' : e.key,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }


  Widget _buildGoalCard() {
    final current = _stats?['visitorsThisMonth'] ?? 0;
    final progress = (current / _monthlyGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.backgroundGrey,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$current sur $_monthlyGoal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (current >= _monthlyGoal)
                      const Icon(Icons.emoji_events, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'nouveaux visiteurs ce mois-ci',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
