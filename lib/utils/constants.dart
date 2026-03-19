class AppConstants {
  // App Info
  static const String appName = 'Focus Aquarium';
  static const String version = '1.0.0';

  // Fake Data
  static const int defaultPoints = 24000;
  static const int defaultLevel = 8;
  static const double totalFocusHours = 85.5;
  static const int totalActivities = 142;
  static const int currentStreak = 15;
  static const int fishCount = 3;
  static const int decorationCount = 5;
  static const int foodStock = 20;

  // Focus Times (minutes)
  static const List<int> focusTimes = [15, 25, 30, 45, 60];

  // Activity Types
  static const List<String> activityTypes = [
    'Running',
    'Reading',
    'Painting',
    'Cooking',
    'Yoga',
    'Swimming',
    'Cycling',
    'Meditation',
  ];

  // Moods
  static const List<String> moods = ['😊', '😐', '😔', '😴', '🔥'];

  // Store Items
  static const Map<String, Map<String, dynamic>> storeItems = {
    'clownfish': {'name': 'Clownfish', 'price': 10, 'icon': '🐠'},
    'goldfish': {'name': 'Goldfish', 'price': 12, 'icon': '🐟'},
    'shrimp': {'name': 'Ornamental Shrimp', 'price': 20, 'icon': '🦐'},
    'pufferfish': {'name': 'Pufferfish', 'price': 50, 'icon': '🐡'},
    'food': {'name': 'Fish Food (1 serving)', 'price': 10, 'icon': '🍖'},
    'seaweed': {'name': 'Seaweed', 'price': 10, 'icon': '🌿'},
    'coral': {'name': 'Coral Reef', 'price': 30, 'icon': '🪸'},
  };

  // Achievements
  static const List<Map<String, dynamic>> achievements = [
    {
      'id': 'focus_master',
      'name': 'Focus Master',
      'description': 'Complete 10 hours of focus',
      'icon': '🏆',
      'unlocked': true,
      'progress': 10,
      'target': 10,
    },
    {
      'id': 'exercise_champion',
      'name': 'Exercise Champion',
      'description': 'Log 10 exercise activities',
      'icon': '🔒',
      'unlocked': false,
      'progress': 0,
      'target': 10,
    },
    {
      'id': 'streak_king',
      'name': 'Streak King',
      'description': 'Maintain 7-day streak',
      'icon': '🔒',
      'unlocked': false,
      'progress': 0,
      'target': 7,
    },
    {
      'id': 'all_rounder',
      'name': 'All Rounder',
      'description': 'Try 5 different activities',
      'icon': '🔒',
      'unlocked': false,
      'progress': 0,
      'target': 5,
    },
    {
      'id': 'aquarium_master',
      'name': 'Aquarium Master',
      'description': 'Own 10 different fishes',
      'icon': '🔒',
      'unlocked': false,
      'progress': 3,
      'target': 10,
    },
    {
      'id': 'early_bird',
      'name': 'Early Bird',
      'description': 'Focus 30 days in a row',
      'icon': '🔒',
      'unlocked': false,
      'progress': 0,
      'target': 30,
    },
  ];
}
