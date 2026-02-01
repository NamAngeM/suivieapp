import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/visitors_list_screen.dart';
import '../screens/follow_up_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/admin_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String visitorsList = '/visitors';
  static const String followUp = '/follow-up';
  static const String statistics = '/statistics';
  static const String admin = '/admin';
  
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    visitorsList: (context) => const VisitorsListScreen(),
    followUp: (context) => const FollowUpScreen(),
    statistics: (context) => const StatisticsScreen(),
    admin: (context) => const AdminScreen(),
  };
}
