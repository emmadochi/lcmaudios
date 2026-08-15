export type IntentCategory = string;
export type MediaType = 'song' | 'sermon' | 'podcast';

export interface CategoryItem {
  id: string;
  categoryKey: string;
  title: string;
  description: string;
  icon: string;
  accentColor: string;
  trackCount: number;
  isActive: boolean;
  createdAt: string;
}

export interface LyricLine {
  id: string;
  trackId: string;
  timestampSeconds: number;
  text: string;
}

export interface SermonNote {
  id: string;
  userId: string;
  trackId: string;
  timestampSeconds: number;
  noteText: string;
  createdAt: string;
}

export interface Track {
  id: string;
  title: string;
  artist: string;
  albumArtUrl: string;
  audioUrl: string;
  duration: number; // in seconds
  subgenre: string;
  intentCategory: IntentCategory;
  mediaType: MediaType;
  isDownloaded?: boolean;
  isFavorite?: boolean;
  isPremium?: boolean;
  playCount?: number;
  lyrics: LyricLine[];
  notes?: SermonNote[];
  createdAt: string;
}

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  fullName: string;
  intentPreferences: IntentCategory[];
  createdAt: string;
}

export interface AnalyticsSummary {
  totalStreams: number;
  activeListeners: number;
  totalListeningHours: number;
  totalNotesTaken: number;
  topCategories: { category: string; count: number; percentage: number }[];
  topTracks: Track[];
}

export interface TelemetryEvent {
  id: string;
  trackId: string;
  durationPlayedSeconds: number;
  timestamp: string;
  createdAt: string;
}
