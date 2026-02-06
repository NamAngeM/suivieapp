import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoe_church_visitors/data/repositories/visitor_repository.dart';
import 'package:zoe_church_visitors/models/visitor.dart';
import '../utils/app_logger.dart';

/// Provider du repository visiteurs
final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  return VisitorRepository();
});

/// État des visiteurs
class VisitorsState {
  final List<Visitor> visitors;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? statusFilter;

  const VisitorsState({
    this.visitors = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
  });

  VisitorsState copyWith({
    List<Visitor>? visitors,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
  }) {
    return VisitorsState(
      visitors: visitors ?? this.visitors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// Visiteurs filtrés selon la recherche et le statut
  List<Visitor> get filteredVisitors {
    var result = visitors;

    // Filtre par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((v) =>
        v.nomComplet.toLowerCase().contains(query) ||
        v.telephone.contains(query) ||
        (v.email?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Filtre par statut
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      result = result.where((v) => v.statut == statusFilter).toList();
    }

    return result;
  }
}

/// Notifier pour la gestion des visiteurs
class VisitorsNotifier extends StateNotifier<VisitorsState> {
  final VisitorRepository _repository;

  VisitorsNotifier(this._repository) : super(const VisitorsState()) {
    loadVisitors();
  }

  /// Charger tous les visiteurs
  Future<void> loadVisitors() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final visitors = await _repository.getVisitors();
      state = VisitorsState(visitors: visitors);
    } catch (e) {
      AppLogger.error('Error loading visitors', tag: 'VisitorsProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur de chargement: $e',
      );
    }
  }

  /// Ajouter un visiteur
  Future<String?> addVisitor(Visitor visitor) async {
    try {
      final id = await _repository.addVisitor(visitor);
      await loadVisitors(); // Recharger la liste
      return id;
    } catch (e) {
      AppLogger.error('Error adding visitor', tag: 'VisitorsProvider', error: e);
      state = state.copyWith(errorMessage: 'Erreur d\'ajout: $e');
      return null;
    }
  }

  /// Mettre à jour un visiteur
  Future<bool> updateVisitor(Visitor visitor) async {
    try {
      await _repository.updateVisitor(visitor);
      await loadVisitors(); // Recharger la liste
      return true;
    } catch (e) {
      AppLogger.error('Error updating visitor', tag: 'VisitorsProvider', error: e);
      state = state.copyWith(errorMessage: 'Erreur de mise à jour: $e');
      return false;
    }
  }

  /// Supprimer un visiteur
  Future<bool> deleteVisitor(String id) async {
    try {
      await _repository.deleteVisitor(id);
      await loadVisitors(); // Recharger la liste
      return true;
    } catch (e) {
      AppLogger.error('Error deleting visitor', tag: 'VisitorsProvider', error: e);
      state = state.copyWith(errorMessage: 'Erreur de suppression: $e');
      return false;
    }
  }

  /// Mettre à jour le filtre de recherche
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Mettre à jour le filtre de statut
  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  /// Réinitialiser les filtres
  void clearFilters() {
    state = state.copyWith(searchQuery: '', statusFilter: null);
  }
}

/// Provider principal des visiteurs
final visitorsProvider = StateNotifierProvider<VisitorsNotifier, VisitorsState>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorsNotifier(repository);
});

/// Provider du stream des visiteurs (temps réel)
final visitorsStreamProvider = StreamProvider<List<Visitor>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return repository.getVisitorsStream();
});

/// Provider pour les visiteurs filtrés
final filteredVisitorsProvider = Provider<List<Visitor>>((ref) {
  return ref.watch(visitorsProvider).filteredVisitors;
});
