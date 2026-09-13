import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalReputationService {
  static double score(Map<String, dynamic> data) {
    final rating = (data['averageRating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (data['reviewCount'] as num?)?.toDouble() ?? 0;
    final completed = (data['completedJobs'] as num?)?.toDouble() ?? 0;
    final bookings = (data['successfulBookings'] as num?)?.toDouble() ?? 0;
    final complaints = (data['complaints'] as num?)?.toDouble() ?? 0;
    final activity = (data['activityScore'] as num?)?.toDouble() ?? 0;
    return (rating * 10) + (reviews.clamp(0, 100) * 0.1) + (completed.clamp(0, 100) * 0.1) + (bookings.clamp(0, 100) * 0.1) + activity - (complaints * 2);
  }

  static String badge(Map<String, dynamic> data) {
    if (data['status'] != 'approved') return 'Pending';
    if (data['manualBadge'] != null) return data['manualBadge'].toString();
    final scoreValue = score(data);
    final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
    if (reviewCount == 0) return 'New Professional';
    if (scoreValue >= 85) return 'Top Rated';
    if (scoreValue >= 65) return 'Trusted Professional';
    return 'Verified';
  }

  static Future<void> recalculate(DocumentReference<Map<String, dynamic>> ref) async {
    final snapshot = await ref.get();
    final data = snapshot.data();
    if (data == null) return;
    await ref.update({'reputationScore': score(data), 'badge': badge(data), 'reputationUpdatedAt': FieldValue.serverTimestamp()});
  }
}
