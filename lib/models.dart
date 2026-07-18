class UserProfile {
  final String id;
  final String name;
  final String photoUrl;
  final String country;
  final String city;
  final String phone;
  final String bio;
  final String email;
  final String role;
  final String verificationStage; // 'unverified', 'basic', 'professional', 'vip'
  final double verificationProgress; // 0.0 to 100.0
  final bool isSponsor;
  final bool isBlocked;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.country,
    required this.city,
    required this.phone,
    required this.bio,
    required this.email,
    required this.role,
    required this.verificationStage,
    required this.verificationProgress,
    required this.isSponsor,
    required this.isBlocked,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      verificationStage: json['verificationStage'] ?? 'unverified',
      verificationProgress: (json['verificationProgress'] ?? 0).toDouble(),
      isSponsor: json['isSponsor'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'country': country,
      'city': city,
      'phone': phone,
      'bio': bio,
      'email': email,
      'role': role,
      'verificationStage': verificationStage,
      'verificationProgress': verificationProgress,
      'isSponsor': isSponsor,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
    };
  }
}

class Professional {
  final String id;
  final String userId;
  final String name;
  final String category; // 'Doctor', 'Lawyer', 'Restaurant', 'Pharmacy', 'Accountant', 'Translator', 'Agency'
  final String country;
  final String city;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String bio;
  final String? imageUrl;
  final String verificationStage; // 'professional', 'vip'
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String status;
  final String createdAt;

  Professional({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.country,
    required this.city,
    required this.phone,
    this.whatsapp,
    this.email,
    this.website,
    required this.bio,
    this.imageUrl,
    required this.verificationStage,
    this.isVerified = false,
    required this.rating,
    required this.reviewCount,
    required this.status,
    required this.createdAt,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      bio: json['bio'] ?? '',
      imageUrl: json['imageUrl'],
      verificationStage: json['verificationStage'] ?? 'professional',
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      status: json['status'] ?? 'approved',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class Job {
  final String id;
  final String userId;
  final String authorName;
  final String authorPhone;
  final String title;
  final String category;
  final String country;
  final String city;
  final double price;
  final String phone;
  final String description;
  final String? imageUrl;
  final bool verified;
  final String status;
  final String createdAt;

  Job({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorPhone,
    required this.title,
    required this.category,
    required this.country,
    required this.city,
    required this.price,
    required this.phone,
    required this.description,
    this.imageUrl,
    required this.verified,
    required this.status,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorPhone: json['authorPhone'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      verified: json['verified'] ?? false,
      status: json['status'] ?? 'approved',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class MarketplaceItem {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String category;
  final double price;
  final String country;
  final String city;
  final String phone;
  final String description;
  final String? imageUrl;
  final String status;
  final String createdAt;

  MarketplaceItem({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.category,
    required this.price,
    required this.country,
    required this.city,
    required this.phone,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'approved',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class EventItem {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String description;
  final String category;
  final String country;
  final String city;
  final String date;
  final String time;
  final String? ticketInfo;
  final String? imageUrl;
  final String status;
  final String createdAt;
  final double? ticketPrice;
  final int? ticketQuantity;
  final int? ticketsSold;

  EventItem({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.category,
    required this.country,
    required this.city,
    required this.date,
    required this.time,
    this.ticketInfo,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    this.ticketPrice,
    this.ticketQuantity,
    this.ticketsSold,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      authorName: json['authorName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      ticketInfo: json['ticketInfo'],
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'approved',
      createdAt: json['createdAt'] ?? '',
      ticketPrice: json['ticketPrice'] != null ? (json['ticketPrice'] as num).toDouble() : null,
      ticketQuantity: json['ticketQuantity'] as int?,
      ticketsSold: json['ticketsSold'] as int?,
    );
  }
}

class DiscussionPost {
  final String id;
  final String authorName;
  final String authorTitle;
  final String authorAvatar;
  final String category;
  final String content;
  int likes;
  int commentsCount;
  final String timestamp;
  bool isLiked;

  DiscussionPost({
    required this.id,
    required this.authorName,
    required this.authorTitle,
    required this.authorAvatar,
    required this.category,
    required this.content,
    required this.likes,
    required this.commentsCount,
    required this.timestamp,
    this.isLiked = false,
  });
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });
}

class ChatParticipant {
  final String name;
  final String photoUrl;

  ChatParticipant({required this.name, required this.photoUrl});
}

class Chat {
  final String id;
  final String participantIds;
  final Map<String, ChatParticipant> participants;
  final String lastMessageText;
  final String lastMessageTime;
  final String? relatedToId;
  final String? relatedToType;
  final String? relatedTitle;

  Chat({
    required this.id,
    required this.participantIds,
    required this.participants,
    required this.lastMessageText,
    required this.lastMessageTime,
    this.relatedToId,
    this.relatedToType,
    this.relatedTitle,
  });
}