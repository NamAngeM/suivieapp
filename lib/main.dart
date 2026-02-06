import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'core/utils/app_logger.dart';
import 'screens/home_screen.dart';
import 'screens/visitors_list_screen.dart';
import 'screens/follow_up_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/admin_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/offline_service.dart';
import 'screens/onboarding_screen.dart';
import 'services/firebase_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  // Initialize Offline Service
  final offlineService = OfflineService();
  await offlineService.initialize();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize Background Tasks (Mobile Only)
  if (!kIsWeb) {
    await BackgroundService.initialize();
    await BackgroundService.schedulePeriodicTasks();
  }
  
  // Schedule daily task reminder (Mobile Only)
  if (!kIsWeb) {
    await notificationService.scheduleDailyTaskReminder();
  }
  
  runApp(const ProviderScope(child: ZoeChurchApp()));
}

class ZoeChurchApp extends StatelessWidget {
  const ZoeChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoe Church - Visiteurs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      VisitorsListScreen(onAddVisitor: () => setState(() => _selectedIndex = 0)),
      const FollowUpScreen(),
      const StatisticsScreen(),
      const AdminScreen(),
    ];
    
    // Vérifier les mises à jour après un court délai
    Future.delayed(const Duration(seconds: 2), () => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    try {
      final config = await FirebaseService.getAppConfig();
      if (config == null) return;

      final latestVersion = config['latestVersion'] as String?;
      final downloadUrl = config['downloadUrl'] as String?;
      final isForceUpdate = config['forceUpdate'] as bool? ?? false;

      if (latestVersion == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (mounted) {
          _showUpdateDialog(latestVersion, downloadUrl, isForceUpdate);
        }
      }
    } catch (e) {
      AppLogger.error('Erreur vérification mise à jour', tag: 'Update', error: e);
    }
  }

  bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
    }
    return false;
  }

  void _showUpdateDialog(String version, String? url, bool force) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text('Une nouvelle version ($version) de l\'application Zoe Church est disponible.'),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (url != null) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Accueil',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Visiteurs',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  icon: Icons.task_alt_outlined,
                  activeIcon: Icons.task_alt,
                  label: 'Suivi',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Stats',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Admin',
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
