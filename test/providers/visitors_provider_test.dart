
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoe_church_visitors/core/providers/visitors_provider.dart';
import 'package:zoe_church_visitors/data/repositories/visitor_repository.dart';
import 'package:zoe_church_visitors/models/visitor.dart';

// Manual Mock to bypass Type inference issues
class ManualMockVisitorRepository implements VisitorRepository {
  List<Visitor> mockVisitors = [];
  bool shouldThrow = false;

  @override
  Future<List<Visitor>> getVisitors() async {
    if (shouldThrow) throw Exception('Network Error');
    return mockVisitors;
  }

  @override
  Future<String> addVisitor(Visitor visitor) async {
    mockVisitors.add(visitor);
    return 'new-id';
  }

  @override
  Future<void> deleteVisitor(String id) async {
    // Return void
  }

  @override
  Future<void> updateVisitor(Visitor visitor) async {
    // Return void
  }

  @override
  Stream<List<Visitor>> getVisitorsStream() {
    return Stream.value(mockVisitors);
  }

  @override
  Future<Visitor?> getVisitor(String id) async {
    return null;
  }

  @override
  Future<List<Visitor>> getVisitorsSince(DateTime date) async {
    return [];
  }
}

void main() {
  late ManualMockVisitorRepository mockRepository;
  late VisitorsNotifier notifier;

  setUp(() {
    mockRepository = ManualMockVisitorRepository();
    notifier = VisitorsNotifier(mockRepository);
  });

  group('VisitorsNotifier Tests', () {
    test('Initial state is empty', () {
      expect(notifier.state.visitors, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('loadVisitors success updates state', () async {
      final visitors = [
        Visitor(
            id: '1',
            nomComplet: 'Test User',
            telephone: '12345678',
            dateEnregistrement: DateTime.now())
      ];
      
      mockRepository.mockVisitors = visitors;

      await notifier.loadVisitors();

      expect(notifier.state.visitors, visitors);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('loadVisitors failure sets errorMessage', () async {
      mockRepository.shouldThrow = true;

      await notifier.loadVisitors();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, contains('Network Error'));
    });

    test('Filtering logic', () async {
       final visitors = [
        Visitor(id: '1', nomComplet: 'Alice', telephone: '111', dateEnregistrement: DateTime.now()),
        Visitor(id: '2', nomComplet: 'Bob', telephone: '222', dateEnregistrement: DateTime.now()),
      ];
      mockRepository.mockVisitors = visitors;
      
      await notifier.loadVisitors(); 

      notifier.setSearchQuery('ali');
      expect(notifier.state.filteredVisitors.length, 1);
      expect(notifier.state.filteredVisitors.first.nomComplet, 'Alice');

      notifier.setSearchQuery('bob');
      expect(notifier.state.filteredVisitors.length, 1);
    });
  });
}
