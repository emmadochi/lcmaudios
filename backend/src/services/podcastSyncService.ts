import { dbClient } from '../data/dbClient';
import { Track } from '../models/types';

export interface PodcastSyncResult {
  success: boolean;
  channelTitle: string;
  channelAuthor: string;
  totalEpisodesInFeed: number;
  newEpisodesAdded: number;
  alreadyExisting: number;
  episodes: {
    id: string;
    title: string;
    duration: number;
    audioUrl: string;
  }[];
}

function cleanCdata(text: string): string {
  if (!text) return '';
  return text
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
}

function parseDurationSeconds(raw: string): number {
  if (!raw) return 300;
  raw = raw.trim();
  if (/^\d+$/.test(raw)) {
    return parseInt(raw, 10);
  }
  const parts = raw.split(':').map((p) => parseInt(p, 10));
  if (parts.length === 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  } else if (parts.length === 2) {
    return parts[0] * 60 + parts[1];
  }
  return 300;
}

export class PodcastSyncService {
  public static async syncFromRss(feedUrl: string): Promise<PodcastSyncResult> {
    console.log(`[PodcastSync] Starting sync from feed: ${feedUrl}`);

    const response = await fetch(feedUrl, {
      headers: {
        'User-Agent': 'LCMAudios-Podcast-Syncer/1.0',
        Accept: 'application/rss+xml, application/xml, text/xml, */*',
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch RSS feed: HTTP ${response.status} ${response.statusText}`);
    }

    const xml = await response.text();

    // Parse channel metadata
    const channelMatch = xml.match(/<channel>([\s\S]*?)<\/channel>/i);
    const channelBlock = channelMatch ? channelMatch[1] : xml;

    const titleMatch = channelBlock.match(/<title>([\s\S]*?)<\/title>/i);
    const channelTitle = cleanCdata(titleMatch ? titleMatch[1] : 'The Peace Word Sparks');

    const authorMatch = channelBlock.match(/<itunes:author>([\s\S]*?)<\/itunes:author>/i) ||
                        channelBlock.match(/<itunes:name>([\s\S]*?)<\/itunes:name>/i);
    let channelAuthor = cleanCdata(authorMatch ? authorMatch[1] : 'Pastor Martins Omonua');
    // Normalize case if all caps
    if (channelAuthor.toUpperCase() === channelAuthor) {
      channelAuthor = channelAuthor
        .toLowerCase()
        .replace(/\b\w/g, (c) => c.toUpperCase());
    }

    const defaultImgMatch = channelBlock.match(/<itunes:image[^>]+href=["']([^"']+)["']/i) ||
                            channelBlock.match(/<image>[\s\S]*?<url>([\s\S]*?)<\/url>/i);
    const defaultCover = defaultImgMatch ? cleanCdata(defaultImgMatch[1]) : 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80';

    // Parse items
    const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
    let match;
    const items: Array<{
      title: string;
      audioUrl: string;
      duration: number;
      coverUrl: string;
      guid: string;
      pubDate: string;
    }> = [];

    while ((match = itemRegex.exec(xml)) !== null) {
      const itemBlock = match[1];

      // Audio enclosure
      const encMatch = itemBlock.match(/<enclosure[^>]+url=["']([^"']+)["']/i);
      if (!encMatch) continue;
      const audioUrl = cleanCdata(encMatch[1]);

      // Title
      const itemTitleMatch = itemBlock.match(/<title>([\s\S]*?)<\/title>/i);
      const title = cleanCdata(itemTitleMatch ? itemTitleMatch[1] : 'Podcast Episode');

      // Duration
      const durMatch = itemBlock.match(/<itunes:duration>([\s\S]*?)<\/itunes:duration>/i);
      const duration = durMatch ? parseDurationSeconds(durMatch[1]) : 300;

      // Cover Art
      const imgMatch = itemBlock.match(/<itunes:image[^>]+href=["']([^"']+)["']/i);
      const coverUrl = imgMatch ? cleanCdata(imgMatch[1]) : defaultCover;

      // GUID
      const guidMatch = itemBlock.match(/<guid[^>]*>([\s\S]*?)<\/guid>/i);
      const guid = cleanCdata(guidMatch ? guidMatch[1] : audioUrl);

      // PubDate
      const pubMatch = itemBlock.match(/<pubDate>([\s\S]*?)<\/pubDate>/i);
      const pubDate = pubMatch ? cleanCdata(pubMatch[1]) : new Date().toISOString();

      items.push({
        title,
        audioUrl,
        duration,
        coverUrl,
        guid,
        pubDate,
      });
    }

    console.log(`[PodcastSync] Extracted ${items.length} episodes from feed.`);

    // Get existing tracks from database
    const existingTracks = await dbClient.getTracks();
    const existingUrlSet = new Set(existingTracks.map((t) => t.audioUrl.trim().toLowerCase()));
    const existingTitleSet = new Set(existingTracks.map((t) => t.title.trim().toLowerCase()));

    let newCount = 0;
    let existingCount = 0;
    const importedEpisodes: { id: string; title: string; duration: number; audioUrl: string }[] = [];

    // Reverse to insert oldest first so newest ends up at top of reverse-chronological catalog
    const chronItems = [...items].reverse();

    for (const ep of chronItems) {
      const normalizedUrl = ep.audioUrl.trim().toLowerCase();
      const normalizedTitle = ep.title.trim().toLowerCase();

      if (existingUrlSet.has(normalizedUrl) || existingTitleSet.has(normalizedTitle)) {
        existingCount++;
        continue;
      }

      const shortId = ep.guid.replace(/[^a-zA-Z0-9]/g, '').slice(-12) || `${Date.now()}`;
      const trackId = `track_spk_${shortId}`;

      const newTrack: Track = {
        id: trackId,
        title: ep.title,
        artist: channelAuthor,
        albumArtUrl: ep.coverUrl,
        audioUrl: ep.audioUrl,
        duration: ep.duration,
        subgenre: 'Podcast Sermon',
        intentCategory: 'morningDevotion',
        categoryKey: 'morningDevotion',
        mediaType: 'podcast',
        isDownloaded: false,
        isFavorite: false,
        isPremium: false,
        playCount: 1,
        lyrics: [],
        createdAt: new Date(ep.pubDate).toISOString() || new Date().toISOString(),
      };

      await dbClient.createTrack(newTrack);
      existingUrlSet.add(normalizedUrl);
      existingTitleSet.add(normalizedTitle);
      newCount++;

      importedEpisodes.push({
        id: trackId,
        title: ep.title,
        duration: ep.duration,
        audioUrl: ep.audioUrl,
      });
    }

    console.log(`[PodcastSync] Completed! Added ${newCount} new episodes, ${existingCount} already present.`);

    return {
      success: true,
      channelTitle,
      channelAuthor,
      totalEpisodesInFeed: items.length,
      newEpisodesAdded: newCount,
      alreadyExisting: existingCount,
      episodes: importedEpisodes,
    };
  }
}
