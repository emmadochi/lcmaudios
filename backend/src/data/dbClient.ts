import { MockDatabase } from './mockDatabase';
import { Track, User, SermonNote, CategoryItem, TelemetryEvent, IntentCategory, MediaType, Minister } from '../models/types';

class DbClient {
  private static instance: DbClient;
  private prisma: any = null;
  private isPrismaConnected: boolean = false;

  private constructor() {
    this.initPrisma();
  }

  public static getInstance(): DbClient {
    if (!DbClient.instance) {
      DbClient.instance = new DbClient();
    }
    return DbClient.instance;
  }

  private async initPrisma() {
    if (process.env.DATABASE_URL) {
      try {
        const { PrismaClient } = require('@prisma/client');
        this.prisma = new PrismaClient();
        await this.prisma.$connect();
        this.isPrismaConnected = true;
        console.log('[DB Client] Connected successfully to PostgreSQL database via Prisma.');
        await this.autoSeedIfEmpty();
      } catch (err) {
        console.warn('[DB Client] PostgreSQL connection failed. Falling back to in-memory MockDatabase.', err);
        this.isPrismaConnected = false;
      }
    } else {
      console.log('[DB Client] DATABASE_URL not set. Running in resilient MockDatabase mode.');
    }
  }

  private async autoSeedIfEmpty() {
    if (!this.prisma) return;
    try {
      const trackCount = await this.prisma.track.count();
      if (trackCount === 0) {
        console.log('[DB Client] 🚀 Fresh PostgreSQL database detected. Seeding baseline tracks and demo data...');
        const mock = MockDatabase.getInstance();

        // Seed demo user
        const userCount = await this.prisma.user.count();
        if (userCount === 0 && mock.users.length > 0) {
          const u = mock.users[0];
          await this.prisma.user.create({
            data: {
              id: u.id,
              email: u.email.toLowerCase(),
              passwordHash: u.passwordHash,
              fullName: u.fullName,
              intentPreferences: u.intentPreferences || ['morningDevotion', 'deepWorship'],
            },
          });
        }

        // Seed initial tracks with lyrics
        for (const t of mock.tracks) {
          await this.prisma.track.create({
            data: {
              id: t.id,
              title: t.title,
              artist: t.artist,
              albumArtUrl: t.albumArtUrl,
              audioUrl: t.audioUrl,
              duration: t.duration,
              subgenre: t.subgenre,
              intentCategory: t.intentCategory as any,
              mediaType: (t.mediaType as any) || 'song',
              playCount: t.playCount || 100,
              lyrics: {
                create: (t.lyrics || []).map((l) => ({
                  timestampSeconds: l.timestampSeconds,
                  text: l.text,
                })),
              },
            },
          });
        }
        // Seed ministers if empty
        const ministerCount = await this.prisma.minister.count();
        if (ministerCount === 0 && mock.ministers.length > 0) {
          for (const m of mock.ministers) {
            await this.prisma.minister.create({
              data: {
                id: m.id,
                name: m.name,
                role: m.role,
                avatarUrl: m.avatarUrl,
                bio: m.bio || '',
                sermonCount: m.sermonCount || 0,
              },
            });
          }
          console.log(`[DB Client] ✅ Successfully seeded ${mock.ministers.length} ministers into PostgreSQL.`);
        }

        console.log(`[DB Client] ✅ Successfully seeded ${mock.tracks.length} tracks with lyrics into PostgreSQL.`);
      }
    } catch (e) {
      console.warn('[DB Client] Auto-seed notice:', e);
    }
  }

  // --- USER OPERATIONS ---
  public async findUserByEmail(email: string): Promise<User | null> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const u = await this.prisma.user.findUnique({ where: { email: email.toLowerCase() } });
        if (u) {
          return {
            id: u.id,
            email: u.email,
            passwordHash: u.passwordHash,
            fullName: u.fullName,
            intentPreferences: u.intentPreferences as IntentCategory[],
            createdAt: u.createdAt.toISOString(),
          };
        }
      } catch (e) {
        console.error('[DB Client] Prisma findUserByEmail error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const user = mock.users.find((u: User) => u.email.toLowerCase() === email.toLowerCase());
    return user || null;
  }

  public async findUserById(id: string): Promise<User | null> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const u = await this.prisma.user.findUnique({ where: { id } });
        if (u) {
          return {
            id: u.id,
            email: u.email,
            passwordHash: u.passwordHash,
            fullName: u.fullName,
            intentPreferences: u.intentPreferences as IntentCategory[],
            createdAt: u.createdAt.toISOString(),
          };
        }
      } catch (e) {
        console.error('[DB Client] Prisma findUserById error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const user = mock.users.find((u: User) => u.id === id);
    return user || null;
  }

  public async createUser(userData: {
    email: string;
    passwordHash: string;
    fullName: string;
    intentPreferences?: string[];
  }): Promise<User> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const created = await this.prisma.user.create({
          data: {
            email: userData.email.toLowerCase(),
            passwordHash: userData.passwordHash,
            fullName: userData.fullName,
            intentPreferences: userData.intentPreferences || ['morningDevotion'],
          },
        });
        return {
          id: created.id,
          email: created.email,
          passwordHash: created.passwordHash,
          fullName: created.fullName,
          intentPreferences: created.intentPreferences as IntentCategory[],
          createdAt: created.createdAt.toISOString(),
        };
      } catch (e) {
        console.error('[DB Client] Prisma createUser error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const newUser: User = {
      id: `usr_${Date.now()}`,
      email: userData.email.toLowerCase(),
      passwordHash: userData.passwordHash,
      fullName: userData.fullName,
      intentPreferences: (userData.intentPreferences as IntentCategory[]) || ['morningDevotion'],
      createdAt: new Date().toISOString(),
    };
    mock.users.push(newUser);
    mock.saveToFile();
    return newUser;
  }

  public async getUsers(): Promise<User[]> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const dbUsers = await this.prisma.user.findMany({
          orderBy: { createdAt: 'desc' },
        });
        return dbUsers.map((u: any) => ({
          id: u.id,
          email: u.email,
          passwordHash: u.passwordHash,
          fullName: u.fullName,
          intentPreferences: u.intentPreferences as IntentCategory[],
          createdAt: u.createdAt.toISOString(),
        }));
      } catch (e) {
        console.error('[DB Client] Prisma getUsers error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    return mock.users;
  }

  public async updateUserPassword(userId: string, newPasswordHash: string): Promise<boolean> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        await this.prisma.user.update({
          where: { id: userId },
          data: { passwordHash: newPasswordHash },
        });
        return true;
      } catch (e) {
        console.error('[DB Client] Prisma updateUserPassword error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const idx = mock.users.findIndex((u: User) => u.id === userId);
    if (idx !== -1) {
      mock.users[idx].passwordHash = newPasswordHash;
      mock.saveToFile();
      return true;
    }
    return false;
  }

  // --- TRACK OPERATIONS ---
  public async getTracks(filter?: {
    intentCategory?: string;
    mediaType?: string;
    search?: string;
  }): Promise<Track[]> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const whereClause: any = {};
        if (filter?.intentCategory && filter.intentCategory !== 'all') {
          whereClause.intentCategory = filter.intentCategory;
        }
        if (filter?.mediaType) {
          whereClause.mediaType = filter.mediaType;
        }
        if (filter?.search) {
          whereClause.OR = [
            { title: { contains: filter.search, mode: 'insensitive' } },
            { artist: { contains: filter.search, mode: 'insensitive' } },
            { subgenre: { contains: filter.search, mode: 'insensitive' } },
          ];
        }

        const tracks = await this.prisma.track.findMany({
          where: whereClause,
          include: { lyrics: true },
          orderBy: { createdAt: 'desc' },
        });

        return tracks.map((t: any) => ({
          id: t.id,
          title: t.title,
          artist: t.artist,
          albumArtUrl: t.albumArtUrl,
          audioUrl: t.audioUrl,
          duration: t.duration,
          subgenre: t.subgenre,
          intentCategory: t.intentCategory as string,
          mediaType: t.mediaType as MediaType,
          isDownloaded: false,
          isFavorite: false,
          isPremium: (t as any).isPremium ?? false,
          playCount: t.playCount || 0,
          createdAt: t.createdAt.toISOString(),
          lyrics: t.lyrics.map((l: any) => ({
            id: l.id,
            trackId: l.trackId,
            timestampSeconds: l.timestampSeconds,
            text: l.text,
          })),
        }));
      } catch (e) {
        console.error('[DB Client] Prisma getTracks error:', e);
      }
    }

    const mock = MockDatabase.getInstance();
    let result = mock.tracks;
    if (filter?.intentCategory && filter.intentCategory !== 'all') {
      result = result.filter((t: Track) => t.intentCategory === filter.intentCategory);
    }
    if (filter?.mediaType) {
      result = result.filter((t: Track) => t.mediaType === filter.mediaType);
    }
    if (filter?.search) {
      const q = filter.search.toLowerCase();
      result = result.filter(
        (t: Track) => t.title.toLowerCase().includes(q) || t.artist.toLowerCase().includes(q) || t.subgenre.toLowerCase().includes(q)
      );
    }
    return result;
  }

  public async getTrackById(id: string): Promise<Track | null> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const t = await this.prisma.track.findUnique({
          where: { id },
          include: { lyrics: true },
        });
        if (t) {
          return {
            id: t.id,
            title: t.title,
            artist: t.artist,
            albumArtUrl: t.albumArtUrl,
            audioUrl: t.audioUrl,
            duration: t.duration,
            subgenre: t.subgenre,
            intentCategory: t.intentCategory as IntentCategory,
            mediaType: t.mediaType as MediaType,
            isPremium: (t as any).isPremium ?? false,
            createdAt: t.createdAt.toISOString(),
            lyrics: t.lyrics.map((l: any) => ({
              id: l.id,
              trackId: l.trackId,
              timestampSeconds: l.timestampSeconds,
              text: l.text,
            })),
          };
        }
      } catch (e) {
        console.error('[DB Client] Prisma getTrackById error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    return mock.tracks.find((t: Track) => t.id === id) || null;
  }

  public async createTrack(trackData: Track): Promise<Track> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const created = await this.prisma.track.create({
          data: {
            title: trackData.title,
            artist: trackData.artist,
            albumArtUrl: trackData.albumArtUrl,
            audioUrl: trackData.audioUrl,
            duration: trackData.duration,
            subgenre: trackData.subgenre,
            intentCategory: trackData.intentCategory as any,
            mediaType: trackData.mediaType as any,
            isPremium: trackData.isPremium ?? false,
            lyrics: {
              create: trackData.lyrics?.map((l: any) => ({
                timestampSeconds: l.timestampSeconds,
                text: l.text,
              })),
            },
          },
          include: { lyrics: true },
        });
        return {
          id: created.id,
          title: created.title,
          artist: created.artist,
          albumArtUrl: created.albumArtUrl,
          audioUrl: created.audioUrl,
          duration: created.duration,
          subgenre: created.subgenre,
          intentCategory: created.intentCategory as IntentCategory,
          mediaType: created.mediaType as MediaType,
          isPremium: (created as any).isPremium ?? trackData.isPremium ?? false,
          createdAt: created.createdAt.toISOString(),
          lyrics: created.lyrics.map((l: any) => ({
            id: l.id,
            trackId: l.trackId,
            timestampSeconds: l.timestampSeconds,
            text: l.text,
          })),
        };
      } catch (e) {
        console.error('[DB Client] Prisma createTrack error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    mock.tracks.unshift(trackData);
    mock.saveToFile();
    return trackData;
  }

  public async updateTrack(id: string, updateData: Partial<Track>): Promise<Track | null> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const dataToUpdate: any = {};
        if (updateData.title !== undefined) dataToUpdate.title = updateData.title;
        if (updateData.artist !== undefined) dataToUpdate.artist = updateData.artist;
        if (updateData.subgenre !== undefined) dataToUpdate.subgenre = updateData.subgenre;
        if (updateData.intentCategory !== undefined) dataToUpdate.intentCategory = updateData.intentCategory;
        if (updateData.mediaType !== undefined) dataToUpdate.mediaType = updateData.mediaType;
        if (updateData.duration !== undefined) dataToUpdate.duration = updateData.duration;
        if (updateData.albumArtUrl !== undefined) dataToUpdate.albumArtUrl = updateData.albumArtUrl;
        if (updateData.audioUrl !== undefined) dataToUpdate.audioUrl = updateData.audioUrl;
        if (updateData.isPremium !== undefined) dataToUpdate.isPremium = updateData.isPremium;

        const updated = await this.prisma.track.update({
          where: { id },
          data: dataToUpdate,
          include: { lyrics: true },
        });
        return {
          id: updated.id,
          title: updated.title,
          artist: updated.artist,
          albumArtUrl: updated.albumArtUrl,
          audioUrl: updated.audioUrl,
          duration: updated.duration,
          subgenre: updated.subgenre,
          intentCategory: updated.intentCategory as IntentCategory,
          mediaType: updated.mediaType as MediaType,
          isPremium: (updated as any).isPremium ?? updateData.isPremium ?? false,
          createdAt: updated.createdAt.toISOString(),
          lyrics: updated.lyrics.map((l: any) => ({
            id: l.id,
            trackId: l.trackId,
            timestampSeconds: l.timestampSeconds,
            text: l.text,
          })),
        };
      } catch (e) {
        console.error('[DB Client] Prisma updateTrack error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const idx = mock.tracks.findIndex((t: Track) => t.id === id);
    if (idx !== -1) {
      // Strip undefined keys from updateData
      const cleanData: any = {};
      for (const key of Object.keys(updateData)) {
        if ((updateData as any)[key] !== undefined) {
          cleanData[key] = (updateData as any)[key];
        }
      }
      mock.tracks[idx] = { ...mock.tracks[idx], ...cleanData };
      mock.saveToFile();
      return mock.tracks[idx];
    }
    return null;
  }

  public async deleteTrack(id: string): Promise<boolean> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        await this.prisma.track.delete({ where: { id } });
        return true;
      } catch (e) {
        console.error('[DB Client] Prisma deleteTrack error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const idx = mock.tracks.findIndex((t: Track) => t.id === id);
    if (idx !== -1) {
      mock.tracks.splice(idx, 1);
      mock.saveToFile();
      return true;
    }
    return false;
  }

  // --- MINISTERS OPERATIONS ---
  public async getMinisters(): Promise<Minister[]> {
    const allTracks = await this.getTracks();

    if (this.isPrismaConnected && this.prisma) {
      try {
        const dbMinisters = await this.prisma.minister.findMany({
          orderBy: { createdAt: 'desc' },
        });
        if (dbMinisters.length > 0) {
          return dbMinisters.map((m: any) => {
            const count = allTracks.filter((t) => t.artist.toLowerCase().includes(m.name.toLowerCase())).length;
            return {
              id: m.id,
              name: m.name,
              role: m.role,
              avatarUrl: m.avatarUrl,
              bio: m.bio,
              sermonCount: count > 0 ? count : m.sermonCount,
              createdAt: m.createdAt.toISOString(),
            };
          });
        }
      } catch (e) {
        console.error('[DB Client] Prisma getMinisters error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    if (!mock.ministers) {
      mock.seedMinisters();
      mock.saveToFile();
    }
    return mock.ministers.map((m) => {
      const count = allTracks.filter((t) => t.artist.toLowerCase().includes(m.name.toLowerCase())).length;
      return {
        ...m,
        sermonCount: count > 0 ? count : m.sermonCount,
      };
    });
  }

  public async getMinisterById(id: string): Promise<Minister | null> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const m = await this.prisma.minister.findUnique({ where: { id } });
        if (m) {
          return {
            id: m.id,
            name: m.name,
            role: m.role,
            avatarUrl: m.avatarUrl,
            bio: m.bio,
            sermonCount: m.sermonCount,
            createdAt: m.createdAt.toISOString(),
          };
        }
      } catch (e) {
        console.error('[DB Client] Prisma getMinisterById error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const minister = mock.ministers.find((m) => m.id === id);
    return minister || null;
  }

  public async createMinister(data: { name: string; role: string; avatarUrl: string; bio?: string }): Promise<Minister> {
    const mock = MockDatabase.getInstance();
    const newMinister: Minister = {
      id: `min_${Date.now()}`,
      name: data.name.trim(),
      role: data.role.trim(),
      avatarUrl: data.avatarUrl,
      bio: data.bio?.trim() || '',
      sermonCount: 0,
      createdAt: new Date().toISOString(),
    };

    if (this.isPrismaConnected && this.prisma) {
      try {
        const created = await this.prisma.minister.create({
          data: {
            id: newMinister.id,
            name: newMinister.name,
            role: newMinister.role,
            avatarUrl: newMinister.avatarUrl,
            bio: newMinister.bio,
            sermonCount: 0,
          },
        });
        newMinister.id = created.id;
      } catch (e) {
        console.error('[DB Client] Prisma createMinister error:', e);
      }
    }

    mock.ministers.unshift(newMinister);
    mock.saveToFile();
    return newMinister;
  }

  public async updateMinister(id: string, updateData: Partial<Minister>): Promise<Minister | null> {
    const mock = MockDatabase.getInstance();

    if (this.isPrismaConnected && this.prisma) {
      try {
        const existing = await this.prisma.minister.findUnique({ where: { id } });
        if (existing) {
          await this.prisma.minister.update({
            where: { id },
            data: updateData,
          });
        } else {
          await this.prisma.minister.create({
            data: {
              id,
              name: updateData.name || 'Minister',
              role: updateData.role || 'Minister',
              avatarUrl: updateData.avatarUrl || 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
              bio: updateData.bio || '',
              sermonCount: updateData.sermonCount || 0,
            },
          });
        }
      } catch (e) {
        console.error('[DB Client] Prisma updateMinister error:', e);
      }
    }

    const idx = mock.ministers.findIndex((m) => m.id === id);
    if (idx !== -1) {
      mock.ministers[idx] = { ...mock.ministers[idx], ...updateData };
      mock.saveToFile();
      return mock.ministers[idx];
    } else {
      const newM: Minister = {
        id,
        name: updateData.name || 'Minister',
        role: updateData.role || 'Minister',
        avatarUrl: updateData.avatarUrl || 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        bio: updateData.bio || '',
        sermonCount: updateData.sermonCount || 0,
        createdAt: new Date().toISOString(),
      };
      mock.ministers.unshift(newM);
      mock.saveToFile();
      return newM;
    }
  }

  public async deleteMinister(id: string): Promise<boolean> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        await this.prisma.minister.delete({ where: { id } });
      } catch (e) {
        console.error('[DB Client] Prisma deleteMinister error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const idx = mock.ministers.findIndex((m) => m.id === id);
    if (idx !== -1) {
      mock.ministers.splice(idx, 1);
      mock.saveToFile();
      return true;
    }
    return false;
  }

  // --- SERMON NOTES OPERATIONS ---
  public async createNote(note: { trackId: string; userId?: string; timestampSeconds: number; noteText: string }): Promise<SermonNote> {
    if (this.isPrismaConnected && this.prisma && note.userId) {
      try {
        const created = await this.prisma.sermonNote.create({
          data: {
            trackId: note.trackId,
            userId: note.userId,
            timestampSeconds: note.timestampSeconds,
            noteText: note.noteText,
          },
        });
        return {
          id: created.id,
          userId: created.userId,
          trackId: created.trackId,
          timestampSeconds: created.timestampSeconds,
          noteText: created.noteText,
          createdAt: created.createdAt.toISOString(),
        };
      } catch (e) {
        console.error('[DB Client] Prisma createNote error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    const newNote: SermonNote = {
      id: `note_${Date.now()}`,
      userId: note.userId || 'usr_demo_1',
      trackId: note.trackId,
      timestampSeconds: note.timestampSeconds,
      noteText: note.noteText,
      createdAt: new Date().toISOString(),
    };
    mock.notes.unshift(newNote);
    mock.saveToFile();
    return newNote;
  }

  public async getNotes(userId?: string): Promise<SermonNote[]> {
    if (this.isPrismaConnected && this.prisma && userId) {
      try {
        const list = await this.prisma.sermonNote.findMany({
          where: { userId },
          orderBy: { createdAt: 'desc' },
        });
        return list.map((n: any) => ({
          id: n.id,
          userId: n.userId,
          trackId: n.trackId,
          timestampSeconds: n.timestampSeconds,
          noteText: n.noteText,
          createdAt: n.createdAt.toISOString(),
        }));
      } catch (e) {
        console.error('[DB Client] Prisma getNotes error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    return mock.notes;
  }

  // --- TELEMETRY OPERATIONS ---
  public async logTelemetry(events: { trackId: string; durationPlayedSeconds: number; timestamp?: string }[]): Promise<number> {
    if (this.isPrismaConnected && this.prisma) {
      try {
        const res = await this.prisma.telemetryEvent.createMany({
          data: events.map((e) => ({
            trackId: e.trackId,
            durationPlayedSeconds: e.durationPlayedSeconds,
            timestamp: e.timestamp ? new Date(e.timestamp) : new Date(),
          })),
        });
        return res.count;
      } catch (e) {
        console.error('[DB Client] Prisma logTelemetry error:', e);
      }
    }
    const mock = MockDatabase.getInstance();
    events.forEach((e) => {
      mock.telemetryEvents.push({
        id: `tel_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
        trackId: e.trackId,
        durationPlayedSeconds: e.durationPlayedSeconds,
        timestamp: e.timestamp || new Date().toISOString(),
        createdAt: new Date().toISOString(),
      });
    });
    mock.saveToFile();
    return events.length;
  }

  // --- CATEGORIES OPERATIONS ---
  public async getCategories(): Promise<CategoryItem[]> {
    const mock = MockDatabase.getInstance();
    
    // Ensure mock categories are initialized
    if (!mock.categories) {
      mock.seedCategories();
      mock.saveToFile();
    }

    // 1. Gather all active tracks from live database
    const allTracks = await this.getTracks();

    // 2. Ensure any tracks with distinct intentCategory (e.g. spiritual-growth, sunday-services) are auto-registered
    allTracks.forEach((t) => {
      if (t.intentCategory) {
        const catKey = t.intentCategory.trim();
        const exists = mock.categories.some(
          (c) =>
            c.categoryKey.toLowerCase() === catKey.toLowerCase() ||
            c.id.toLowerCase() === catKey.toLowerCase() ||
            c.title.toLowerCase() === catKey.toLowerCase()
        );
        if (!exists) {
          const formattedTitle = catKey
            .replace(/[-_]/g, ' ')
            .replace(/\b\w/g, (l) => l.toUpperCase());
          mock.categories.push({
            id: `cat_${catKey.replace(/[^\w]/g, '_')}`,
            categoryKey: catKey,
            title: formattedTitle,
            description: `${formattedTitle} sermon series & devotionals`,
            icon: 'auto_awesome_rounded',
            accentColor: '#E63946',
            trackCount: 0,
            isActive: true,
            createdAt: new Date().toISOString(),
          });
          mock.saveToFile();
        }
      }
    });

    // 3. Compute accurate live track counts for each category
    return mock.categories.map((c) => {
      const count = allTracks.filter(
        (t) =>
          t.intentCategory?.toLowerCase() === c.categoryKey.toLowerCase() ||
          t.intentCategory?.toLowerCase() === c.title.toLowerCase() ||
          t.intentCategory?.toLowerCase() === c.id.toLowerCase()
      ).length;
      return {
        ...c,
        trackCount: count,
      };
    });
  }

  public async createCategory(cat: Omit<CategoryItem, 'id' | 'createdAt' | 'trackCount'>): Promise<CategoryItem> {
    const mock = MockDatabase.getInstance();
    const newCat: CategoryItem = {
      id: `cat_${Date.now()}`,
      categoryKey: cat.categoryKey.trim(),
      title: cat.title.trim(),
      description: cat.description ? cat.description.trim() : '',
      icon: cat.icon || 'auto_awesome_rounded',
      accentColor: cat.accentColor || '#E63946',
      trackCount: 0,
      isActive: cat.isActive !== undefined ? cat.isActive : true,
      createdAt: new Date().toISOString(),
    };
    mock.categories.push(newCat);
    mock.saveToFile();
    return newCat;
  }

  public async updateCategory(id: string, updates: Partial<CategoryItem>): Promise<CategoryItem | null> {
    const mock = MockDatabase.getInstance();
    const cat = mock.categories.find((c: CategoryItem) => c.id === id);
    if (!cat) return null;
    const oldKey = cat.categoryKey;
    const oldTitle = cat.title;

    Object.assign(cat, updates);

    // If key or title changed, cascade to existing tracks in MockDatabase
    if (updates.categoryKey && updates.categoryKey !== oldKey) {
      mock.tracks.forEach((t) => {
        if (t.intentCategory === oldKey || t.intentCategory === oldTitle) {
          t.intentCategory = updates.categoryKey!;
        }
      });
    }

    mock.saveToFile();
    return cat;
  }

  public async deleteCategory(id: string): Promise<boolean> {
    const mock = MockDatabase.getInstance();
    const idx = mock.categories.findIndex((c: CategoryItem) => c.id === id);
    if (idx !== -1) {
      mock.categories.splice(idx, 1);
      mock.saveToFile();
      return true;
    }
    return false;
  }
}

export const dbClient = DbClient.getInstance();
