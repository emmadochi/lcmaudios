import { PodcastSyncService } from '../services/podcastSyncService';

async function main() {
  const feedUrl = 'https://media.rss.com/the-peace-word-sparks/feed.xml';
  console.log('Starting sync for:', feedUrl);
  const result = await PodcastSyncService.syncFromRss(feedUrl);
  console.log(`[SUCCESS] Channel: ${result.channelTitle} (${result.channelAuthor})`);
  console.log(`[SUCCESS] Total episodes in feed: ${result.totalEpisodesInFeed}`);
  console.log(`[SUCCESS] New episodes added: ${result.newEpisodesAdded}`);
  console.log(`[SUCCESS] Already existing: ${result.alreadyExisting}`);
}

main().catch((err) => {
  console.error('Error during sync:', err);
  process.exit(1);
});
