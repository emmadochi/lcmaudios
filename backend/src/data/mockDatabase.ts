import { Track, User, SermonNote, CategoryItem, TelemetryEvent } from '../models/types';
import bcrypt from 'bcryptjs';

export class MockDatabase {
  private static instance: MockDatabase;

  public users: User[] = [];
  public tracks: Track[] = [];
  public notes: SermonNote[] = [];
  public categories: CategoryItem[] = [];
  public telemetryEvents: TelemetryEvent[] = [];

  private constructor() {
    this.seedData();
  }

  public static getInstance(): MockDatabase {
    if (!MockDatabase.instance) {
      MockDatabase.instance = new MockDatabase();
    }
    return MockDatabase.instance;
  }

  private seedData() {
    // Seed initial demo user
    const salt = bcrypt.genSaltSync(10);
    const demoPasswordHash = bcrypt.hashSync('password123', salt);

    this.users.push({
      id: 'usr_demo_1',
      email: 'worshipper@lcmaudios.com',
      passwordHash: demoPasswordHash,
      fullName: 'Grace Worship Community',
      intentPreferences: ['morningDevotion', 'deepWorship'],
      createdAt: new Date().toISOString(),
    });

    // Seed Categories
    this.categories = [
      {
        id: 'cat_1',
        categoryKey: 'morningDevotion',
        title: 'Morning Devotion',
        description: 'Start your day with uplifting praise & scripture',
        icon: 'wb_sunny_rounded',
        accentColor: '#F59E0B',
        trackCount: 24,
        isActive: true,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'cat_2',
        categoryKey: 'deepWorship',
        title: 'Deep Worship',
        description: 'Immersive intimate worship & quiet reflection',
        icon: 'auto_awesome_rounded',
        accentColor: '#8B5CF6',
        trackCount: 18,
        isActive: true,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'cat_3',
        categoryKey: 'warfarePrayers',
        title: 'Warfare Prayers',
        description: 'High-energy spiritual declarations & prayers',
        icon: 'shield_rounded',
        accentColor: '#E63946',
        trackCount: 30,
        isActive: true,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'cat_4',
        categoryKey: 'studyFocus',
        title: 'Bible Study',
        description: 'Calming instrumental devotionals for focus',
        icon: 'menu_book_rounded',
        accentColor: '#06B6D4',
        trackCount: 15,
        isActive: true,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'cat_5',
        categoryKey: 'deliverance',
        title: 'Deliverance & Healing',
        description: 'Faith declarations for divine healing & freedom',
        icon: 'health_and_safety_rounded',
        accentColor: '#10B981',
        trackCount: 12,
        isActive: true,
        createdAt: new Date().toISOString(),
      },
    ];

    // Seed initial tracks
    this.tracks = [
      {
        id: 'track_1',
        title: 'Atmosphere of Grace & Glory',
        artist: 'Nathaniel Bassey & LCM Worship',
        albumArtUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: 342,
        subgenre: 'Deep Worship',
        intentCategory: 'deepWorship',
        mediaType: 'song',
        isDownloaded: true,
        isFavorite: true,
        playCount: 1420,
        createdAt: new Date().toISOString(),
        lyrics: [
          { id: 'lyr_1', trackId: 'track_1', timestampSeconds: 0, text: '[Instrumental Prelude]' },
          { id: 'lyr_2', trackId: 'track_1', timestampSeconds: 12, text: 'Let your glory fill this sacred place' },
          { id: 'lyr_3', trackId: 'track_1', timestampSeconds: 24, text: 'We bow in awe before your throne of grace' },
          { id: 'lyr_4', trackId: 'track_1', timestampSeconds: 38, text: 'Holy Holy, Almighty is the Lord' },
          { id: 'lyr_5', trackId: 'track_1', timestampSeconds: 52, text: 'Forever faithful is your holy word' },
          { id: 'lyr_6', trackId: 'track_1', timestampSeconds: 70, text: 'Spirit move, break every heavy chain' },
          { id: 'lyr_7', trackId: 'track_1', timestampSeconds: 88, text: 'Let your living water fall like rain' },
        ],
      },
      {
        id: 'track_2',
        title: 'Morning Mercies & Devotional Declaration',
        artist: 'Pastor Enoch Adeboye',
        albumArtUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: 1110,
        subgenre: 'Spoken Sermon',
        intentCategory: 'morningDevotion',
        mediaType: 'sermon',
        isDownloaded: false,
        isFavorite: true,
        playCount: 980,
        createdAt: new Date().toISOString(),
        lyrics: [
          { id: 'lyr_8', trackId: 'track_2', timestampSeconds: 0, text: 'Welcome to this morning devotional broadcast.' },
          { id: 'lyr_9', trackId: 'track_2', timestampSeconds: 15, text: 'Lamentations 3:22 tells us His mercies are new every morning.' },
          { id: 'lyr_10', trackId: 'track_2', timestampSeconds: 40, text: 'Speak to your day before the sun rises above the horizon.' },
          { id: 'lyr_11', trackId: 'track_2', timestampSeconds: 65, text: 'Declare: I am blessed, favored, and preserved by His covenant.' },
        ],
      },
      {
        id: 'track_3',
        title: 'Warfare & Spiritual Breakthrough',
        artist: 'Apostle Joshua Selman',
        albumArtUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: 1515,
        subgenre: 'Warfare Prayer',
        intentCategory: 'warfarePrayers',
        mediaType: 'sermon',
        isDownloaded: true,
        isFavorite: false,
        playCount: 1850,
        createdAt: new Date().toISOString(),
        lyrics: [
          { id: 'lyr_12', trackId: 'track_3', timestampSeconds: 0, text: 'Lift up your heads, O ye gates!' },
          { id: 'lyr_13', trackId: 'track_3', timestampSeconds: 20, text: 'Every stronghold contrary to your destiny is broken now.' },
          { id: 'lyr_14', trackId: 'track_3', timestampSeconds: 45, text: 'The weapons of our warfare are not carnal, but mighty through God.' },
        ],
      },
      {
        id: 'track_4',
        title: 'Silent Waters (Piano Meditation)',
        artist: 'LCM Instrumental Sanctuary',
        albumArtUrl: 'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        duration: 725,
        subgenre: 'Soaking Instrumental',
        intentCategory: 'studyFocus',
        mediaType: 'song',
        isDownloaded: false,
        isFavorite: true,
        playCount: 640,
        createdAt: new Date().toISOString(),
        lyrics: [
          { id: 'lyr_15', trackId: 'track_4', timestampSeconds: 0, text: '[Calming Soaking Piano & Ambient Pads]' },
          { id: 'lyr_16', trackId: 'track_4', timestampSeconds: 60, text: 'Be still and know that I am God. (Psalm 46:10)' },
        ],
      },
    ];

    // Seed sample note
    this.notes.push({
      id: 'note_seed_1',
      userId: 'usr_demo_1',
      trackId: 'track_1',
      timestampSeconds: 38,
      noteText: 'Key Revelation: Worship invites God\'s tangible presence into our daily battles.',
      createdAt: new Date().toISOString(),
    });
  }
}
