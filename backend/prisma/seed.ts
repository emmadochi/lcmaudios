import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('[Seed] 🌱 Starting database seed...');

  // ─── Demo User ────────────────────────────────────────────────
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash('password123', salt);

  const demoUser = await prisma.user.upsert({
    where: { email: 'worshipper@lcmaudios.com' },
    update: {},
    create: {
      id: 'usr_demo_1',
      email: 'worshipper@lcmaudios.com',
      passwordHash,
      fullName: 'Grace Worship Community',
      intentPreferences: ['morningDevotion', 'deepWorship'],
    },
  });
  console.log(`[Seed] ✅ Demo user: ${demoUser.email}`);

  // ─── Tracks & Lyrics ──────────────────────────────────────────
  const tracksData = [
    {
      id: 'track_1',
      title: 'Atmosphere of Grace & Glory',
      artist: 'Nathaniel Bassey & LCM Worship',
      albumArtUrl:
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: 342,
      subgenre: 'Deep Worship',
      intentCategory: 'deepWorship' as const,
      mediaType: 'song' as const,
      lyrics: [
        { timestampSeconds: 0,  text: '[Instrumental Prelude]' },
        { timestampSeconds: 12, text: 'Let your glory fill this sacred place' },
        { timestampSeconds: 24, text: 'We bow in awe before your throne of grace' },
        { timestampSeconds: 38, text: 'Holy Holy, Almighty is the Lord' },
        { timestampSeconds: 52, text: 'Forever faithful is your holy word' },
        { timestampSeconds: 70, text: 'Spirit move, break every heavy chain' },
        { timestampSeconds: 88, text: 'Let your living water fall like rain' },
      ],
    },
    {
      id: 'track_2',
      title: 'Morning Mercies & Devotional Declaration',
      artist: 'Pastor Enoch Adeboye',
      albumArtUrl:
        'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: 1110,
      subgenre: 'Spoken Sermon',
      intentCategory: 'morningDevotion' as const,
      mediaType: 'sermon' as const,
      lyrics: [
        { timestampSeconds: 0,  text: 'Welcome to this morning devotional broadcast.' },
        { timestampSeconds: 15, text: 'Lamentations 3:22 tells us His mercies are new every morning.' },
        { timestampSeconds: 40, text: 'Speak to your day before the sun rises above the horizon.' },
        { timestampSeconds: 65, text: 'Declare: I am blessed, favored, and preserved by His covenant.' },
      ],
    },
    {
      id: 'track_3',
      title: 'Warfare & Spiritual Breakthrough',
      artist: 'Apostle Joshua Selman',
      albumArtUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: 1515,
      subgenre: 'Warfare Prayer',
      intentCategory: 'warfarePrayers' as const,
      mediaType: 'sermon' as const,
      lyrics: [
        { timestampSeconds: 0,  text: 'Lift up your heads, O ye gates!' },
        { timestampSeconds: 20, text: 'Every stronghold contrary to your destiny is broken now.' },
        { timestampSeconds: 45, text: 'The weapons of our warfare are not carnal, but mighty through God.' },
      ],
    },
    {
      id: 'track_4',
      title: 'Silent Waters (Piano Meditation)',
      artist: 'LCM Instrumental Sanctuary',
      albumArtUrl:
        'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?auto=format&fit=crop&w=800&q=80',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: 725,
      subgenre: 'Soaking Instrumental',
      intentCategory: 'studyFocus' as const,
      mediaType: 'song' as const,
      lyrics: [
        { timestampSeconds: 0,  text: '[Calming Soaking Piano & Ambient Pads]' },
        { timestampSeconds: 60, text: 'Be still and know that I am God. (Psalm 46:10)' },
      ],
    },
  ];

  for (const t of tracksData) {
    const { lyrics, ...trackFields } = t;
    const track = await prisma.track.upsert({
      where: { id: t.id },
      update: {},
      create: {
        ...trackFields,
        lyrics: { create: lyrics },
      },
    });
    console.log(`[Seed] ✅ Track: "${track.title}"`);
  }

  // ─── Sample Sermon Note ────────────────────────────────────────
  await prisma.sermonNote.upsert({
    where: { id: 'note_seed_1' },
    update: {},
    create: {
      id: 'note_seed_1',
      userId: demoUser.id,
      trackId: 'track_1',
      timestampSeconds: 38,
      noteText: "Key Revelation: Worship invites God's tangible presence into our daily battles.",
    },
  });
  console.log('[Seed] ✅ Sample sermon note seeded.');

  console.log('[Seed] 🎉 Database seed complete!');
}

main()
  .catch((e) => {
    console.error('[Seed] ❌ Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
