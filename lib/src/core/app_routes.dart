import 'package:flutter/material.dart';
import 'package:arthatrack/main_screen.dart';
import 'package:arthatrack/screens/auth/login_screen.dart';
import 'package:arthatrack/screens/dashboard/dashboard_screen.dart';
import 'package:arthatrack/screens/statistic/statistic_screen.dart';
import 'package:arthatrack/screens/chat/chat_screen.dart';
import 'package:arthatrack/screens/target/target_screen.dart';
import 'package:arthatrack/screens/profile/profile_screen.dart';
import 'package:arthatrack/screens/transaction/add_transaction_screen.dart';
import 'package:arthatrack/screens/transaction/transaction_history_screen.dart';
import 'package:arthatrack/screens/transaction/currency_conversion_screen.dart';
import 'package:arthatrack/screens/timezone/time_conversion_screen.dart';
import 'package:arthatrack/screens/map/expenditure_map_screen.dart';
import 'package:arthatrack/screens/minigame/currency_quiz_screen.dart';
import 'package:arthatrack/screens/profile/change_password_screen.dart';
import 'package:arthatrack/screens/profile/edit_profile_screen.dart';
import 'package:arthatrack/screens/profile/feedback_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String statistic = '/statistic';
  static const String chat = '/chat';
  static const String target = '/target';
  static const String profile = '/profile';
  static const String addTransaction = '/transaction/add';
  static const String transactionHistory = '/transaction/history';
  static const String currencyConversion = '/transaction/conversion';
  static const String timezone = '/timezone';
  static const String maps = '/maps';
  static const String minigame = '/minigame';
  static const String changePassword = '/profile/change_password';
  static const String editProfile = '/profile/edit';
  static const String feedback = '/profile/feedback';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case dashboard:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case statistic:
        return MaterialPageRoute(builder: (_) => const StatisticScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case target:
        return MaterialPageRoute(builder: (_) => const TargetScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(
            initialType: args?['initialType'] ?? 'expense',
            existingTransaction: args?['existingTransaction'],
          ),
        );
      case transactionHistory:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TransactionHistoryScreen(
            initialFilter: args?['initialFilter'],
          ),
        );
      case currencyConversion:
        return MaterialPageRoute(
            builder: (_) => CurrencyConversionScreen());
      case timezone:
        return MaterialPageRoute(builder: (_) => const TimeConversionScreen());
      case maps:
        return MaterialPageRoute(builder: (_) => const ExpenditureMapScreen());
      case minigame:
        return MaterialPageRoute(builder: (_) => const CurrencyQuizScreen());
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case editProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(
            currentName: args?['currentName'] ?? '',
            currentBio: args?['currentBio'] ?? '',
          ),
        );
      case feedback:
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());
      case login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
