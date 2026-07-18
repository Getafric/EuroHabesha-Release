class SessionState {
  static bool isGuest = true;
  static bool isVerified = false;
  static bool isApproved = false;
  static String? verifiedContact;
  static String? currentUid;
  static String? displayName;

  static void enterGuest() {
    isGuest = true;
    isVerified = false;
    isApproved = false;
    verifiedContact = null;
    currentUid = null;
    displayName = null;
  }

  static void markVerified(
    String contact, {
    bool approved = true,
    String? uid,
    String? name,
  }) {
    isGuest = false;
    isVerified = true;
    isApproved = approved;
    verifiedContact = contact;
    currentUid = uid;
    displayName = name;
  }

  static void markPendingApproval(String contact, {String? uid, String? name}) {
    isGuest = false;
    isVerified = true;
    isApproved = false;
    verifiedContact = contact;
    currentUid = uid;
    displayName = name;
  }
}
