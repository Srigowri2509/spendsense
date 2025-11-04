class Endpoints {
  static const String base = '/api/v1';

  // Server
  static const String serverCheck = '$base/server-check';

  // User
  static const String register = '$base/user/register';
  static const String login = '$base/user/login';
  static const String getCurrentUser = '$base/user/u/get-current-User';
  static const String updateUser = '$base/user/u/update-user';
  static const String sendResetOtp = '$base/user/send-reset-otp';
  static const String verifyResetOtp = '$base/user/verify-reset-otp';
  static const String resetPassword = '$base/user/reset-password';

  // OTP (login/verification)
  static const String sendOtp = '$base/otp/o/send-otp';
  static const String verifyOtp = '$base/otp/o/verify-otp';

  // Expenses
  static const String addExpense = '$base/user-expense/add-expense';
  static const String removeExpense = '$base/user-expense/remove-expense';
  static const String updateExpense = '$base/user-expense/update-expense';
  static const String allExpense = '$base/user-expense/e/allExpense/';
  static const String monthlyCategorySpending = '$base/user-expense/m/monthlyCategorySpending';
  static const String yearlyCategorySpending = '$base/user-expense/y/yearlyCategorySpending';
  static const String totalExpense = '$base/user-expense/t/totalExpense';

  // Streak
  static const String updateUserStreak = '$base/user-streak/update-user-streak';
  static const String currentUserStreak = '$base/user-streak/current-user-streak';
}


