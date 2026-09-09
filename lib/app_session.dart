class AppSession {
  static bool isGuest = true;
  static bool isEmailVerified = false;
  static bool isSuperAdmin = false;
  static List<String> roles = [];
  static String displayName = 'Guest mode';
  static String email = '';
  static String city = 'Browse Euro Habesha';
  static String phone = '';

  static void continueAsGuest() {
    isGuest = true;
    isEmailVerified = false;
    isSuperAdmin = false;
    roles = [];
    displayName = 'Guest mode';
    email = '';
    city = 'Browse Euro Habesha';
    phone = '';
  }

  static void signIn({
    required String name,
    required String emailAddress,
    bool verified = true,
    List<String> assignedRoles = const [],
    bool superAdminValidated = false,
  }) {
    isGuest = false;
    isEmailVerified = verified;
    isSuperAdmin = superAdminValidated && emailAddress.toLowerCase() == 'getafricshow1@gmail.com';
    roles = isSuperAdmin ? ['superAdmin'] : assignedRoles;
    displayName = name.trim().isEmpty ? emailAddress : name.trim();
    email = emailAddress;
    city = 'Set your city in profile settings';
    phone = '';
  }

  static void signOut() {
    continueAsGuest();
  }
}