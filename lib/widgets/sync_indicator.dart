import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/offline_service.dart';

class SyncIndicator extends StatefulWidget {
  final bool showLabel;
  
  const SyncIndicator({
    super.key,
    this.showLabel = true,
  });

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> with SingleTickerProviderStateMixin {
  final _offlineService = OfflineService();
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _isSyncing = false;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _loadStatus();
    _listenToChanges();
  }

  Future<void> _loadStatus() async {
    _isOnline = _offlineService.isOnline;
    _pendingCount = await _offlineService.getPendingCount();
    if (mounted) setState(() {});
  }

  void _listenToChanges() {
    _offlineService.onlineStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
    
    _offlineService.pendingCountStream.listen((count) {
      if (mounted) {
        setState(() => _pendingCount = count);
      }
    });
  }

  Future<void> _syncNow() async {
    if (!_isOnline || _isSyncing) return;
    
    setState(() => _isSyncing = true);
    _animationController.repeat();
    
    try {
      final synced = await _offlineService.syncPendingVisitors();
      if (mounted && synced > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$synced visiteur${synced > 1 ? 's' : ''} synchronisé${synced > 1 ? 's' : ''} !'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pendingCount > 0 ? _syncNow : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de statut
            _buildStatusIcon(),
            
            if (widget.showLabel) ...[
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ],
            
            // Badge de compteur
            if (_pendingCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isSyncing) {
      return RotationTransition(
        turns: _animationController,
        child: Icon(
          Icons.sync,
          size: 16,
          color: _getTextColor(),
        ),
      );
    }
    
    if (!_isOnline) {
      return Icon(
        Icons.cloud_off,
        size: 16,
        color: _getTextColor(),
      );
    }
    
    if (_pendingCount > 0) {
      return Icon(
        Icons.cloud_upload,
        size: 16,
        color: _getTextColor(),
      );
    }
    
    return Icon(
      Icons.cloud_done,
      size: 16,
      color: _getTextColor(),
    );
  }

  Color _getBackgroundColor() {
    if (!_isOnline) {
      return Colors.grey[200]!;
    }
    if (_pendingCount > 0) {
      return AppTheme.accentOrange.withOpacity(0.15);
    }
    return AppTheme.accentGreen.withOpacity(0.15);
  }

  Color _getTextColor() {
    if (!_isOnline) {
      return Colors.grey[600]!;
    }
    if (_pendingCount > 0) {
      return AppTheme.accentOrange;
    }
    return AppTheme.accentGreen;
  }

  String _getStatusText() {
    if (_isSyncing) {
      return 'Synchronisation...';
    }
    if (!_isOnline) {
      return 'Hors ligne';
    }
    if (_pendingCount > 0) {
      return 'En attente';
    }
    return 'Synchronisé';
  }
}

/// Version compacte pour la barre de navigation
class SyncIndicatorCompact extends StatelessWidget {
  const SyncIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncIndicator(showLabel: false);
  }
}
