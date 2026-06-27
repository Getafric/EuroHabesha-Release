export type UserRole = 'admin' | 'professional' | 'user';
export type UserStatus = 'pending' | 'approved' | 'rejected';
export type VerificationStatus = 'unverified' | 'pending' | 'verified';

export interface User {
  id: string;
  name: string;
  phone: string;
  country: string;
  prefix: string;
  languages: string[];
  role: UserRole;
  isBlocked: boolean;
  verificationStatus: VerificationStatus;
  verificationDocName?: string;
  verificationDocType?: string;
  createdAt: string;
}

export type ListingType = 'job' | 'marketplace' | 'event' | 'professional';

export interface AIReviewResult {
  approved: boolean;
  score: number; // 0-100
  reason: string;
  suggestedCategory?: string;
  improvements?: string;
}

export interface ListingReview {
  id: string;
  authorId: string;
  authorName: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface Listing {
  id: string;
  type: ListingType;
  category: string;
  title: string;
  description: string;
  price?: string; // Optional (mainly for marketplace, rentals)
  location: {
    city: string;
    country: string;
  };
  date?: string; // Optional (mainly for events)
  image?: string; // Optional custom image URL or icon identifier
  experience?: string; // Optional (mainly for jobs)
  spokenLanguages?: string[]; // Spoken languages
  phone: string;
  whatsapp: string;
  isVerified: boolean;
  status: 'pending' | 'approved' | 'rejected';
  authorId: string;
  authorName: string;
  createdAt: string;
  aiReview?: AIReviewResult;
  reviews?: ListingReview[];
  averageRating?: number;
}

export interface ChatMessage {
  id: string;
  channel: string; // 'general' | 'jobs' | 'marketplace' | 'events' | 'professionals'
  senderId: string;
  senderName: string;
  senderRole: UserRole;
  senderIsVerified: boolean;
  content: string;
  createdAt: string;
}

export interface SystemNotification {
  id: string;
  title: string;
  content: string;
  type: 'info' | 'success' | 'warning';
  createdAt: string;
}

export interface AppStats {
  totalUsers: number;
  totalListings: number;
  totalEvents: number;
  totalProfessionals: number;
  pendingVerifications: number;
  pendingListings: number;
}
