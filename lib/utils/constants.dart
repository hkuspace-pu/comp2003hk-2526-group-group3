class AppConstants {
  static const String appName = 'Focus Aquarium';
  static const String version = '1.0.0';
  static const List<int> focusTimes = [15, 25, 30, 45, 60];
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

  static const List<String> moods = ['😊', '😐', '😔', '😴', '🔥'];
  static const Map<String, Map<String, dynamic>> storeItems = {
    'clownfish': {'name': 'Clownfish', 'price': 50, 'icon': '🐠'},
    'goldfish': {'name': 'Goldfish', 'price': 70, 'icon': '🐟'},
    'shrimp': {'name': 'Shrimp', 'price': 60, 'icon': '🦐'},
    'pufferfish': {'name': 'Pufferfish', 'price': 80, 'icon': '🐡'},
    'bluefish': {'name': 'Bluefish', 'price': 90, 'icon': '🐟'},
    'lucky': {'name': 'Lucky Draw', 'price': 100, 'icon': '🎰'},
    'food': {'name': 'Fish Food (1 serving)', 'price': 30, 'icon': '🍖'},
  };

  // achievement list, keep same as achievements_screen.dart so wont mismatch
  static const List<Map<String, dynamic>> achievements = [
    {
      'id': 'focus_master',
      'name': 'Focus Master',
      'description': 'Complete 10 hours of focus',
      'icon': '🏆',
      'unlocked': false,
      'progress': 0,
      'target': 10,
    },
    {
      'id': 'first_session',
      'name': 'First Step',
      'description': 'Complete your first focus session',
      'icon': '🎯',
      'unlocked': false,
      'progress': 0,
      'target': 1,
    },
    {
      'id': 'session_10',
      'name': 'Focused Mind',
      'description': 'Complete 10 focus sessions',
      'icon': '🧠',
      'unlocked': false,
      'progress': 0,
      'target': 10,
    },
    {
      'id': 'exercise_champion',
      'name': 'Active Life',
      'description': 'Log 10 off-screen activities',
      'icon': '🏃',
      'unlocked': false,
      'progress': 0,
      'target': 10,
    },
    {
      'id': 'streak_7',
      'name': 'Streak King',
      'description': 'Maintain a 7-day streak',
      'icon': '🔥',
      'unlocked': false,
      'progress': 0,
      'target': 7,
    },
    {
      'id': 'streak_30',
      'name': 'Early Bird',
      'description': 'Maintain a 30-day streak',
      'icon': '🌅',
      'unlocked': false,
      'progress': 0,
      'target': 30,
    },
    {
      'id': 'aquarium_starter',
      'name': 'Fish Keeper',
      'description': 'Own your first fish',
      'icon': '🐠',
      'unlocked': false,
      'progress': 0,
      'target': 1,
    },
    {
      'id': 'aquarium_master',
      'name': 'Aquarium Master',
      'description': 'Own 5 different fish species',
      'icon': '🐟',
      'unlocked': false,
      'progress': 0,
      'target': 5,
    },
    {
      'id': 'points_100',
      'name': 'Point Collector',
      'description': 'Earn 100 total points',
      'icon': '💰',
      'unlocked': false,
      'progress': 0,
      'target': 100,
    },
    {
      'id': 'points_1000',
      'name': 'Point Master',
      'description': 'Earn 1,000 total points',
      'icon': '💎',
      'unlocked': false,
      'progress': 0,
      'target': 1000,
    },
  ];

  static const Map<String, double> luckyWeights = {
    'clownfish': 50,
    'goldfish': 30,
    'shrimp': 15,
    'pufferfish': 4,
    'bluefish': 1
  };
}
