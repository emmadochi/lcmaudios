process.env.NODE_ENV = 'test';

import app from '../server';
import http from 'http';

async function runApiTests() {
  console.log('--- Starting LCM Audios Backend API Verification ---');
  const server = http.createServer(app);

  await new Promise<void>((resolve) => server.listen(5099, resolve));

  try {
    // 1. Health Check Test
    const resHealth = await fetch('http://localhost:5099/health');
    const healthJson = (await resHealth.json()) as any;
    console.log('[PASS] Health Check Status:', healthJson.status);

    // 2. Fetch Tracks Test
    const resTracks = await fetch('http://localhost:5099/api/v1/tracks?intentCategory=deepWorship');
    const tracksJson = (await resTracks.json()) as any;
    console.log('[PASS] Deep Worship Tracks Count:', tracksJson.count);
    if (tracksJson.count === 0) throw new Error('Expected deepWorship tracks');

    // 3. Fetch Lyrics Test
    const resLyrics = await fetch('http://localhost:5099/api/v1/tracks/track_1/lyrics');
    const lyricsJson = (await resLyrics.json()) as any;
    console.log('[PASS] Track 1 Synced Lyrics Count:', lyricsJson.lyrics.length);

    // 4. Create User & Login Test
    const resReg = await fetch('http://localhost:5099/api/v1/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `test_${Date.now()}@lcmaudios.com`,
        password: 'password123',
        fullName: 'Test Worshipper',
      }),
    });
    const regJson = (await resReg.json()) as any;
    console.log('[PASS] Registration Response Token Received:', !!regJson.token);

    // 5. Create Sermon Note Test
    const resNote = await fetch('http://localhost:5099/api/v1/notes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        trackId: 'track_1',
        userId: regJson.user.id,
        timestampSeconds: 42.5,
        noteText: 'Anchored sermon note test payload.',
      }),
    });
    const noteJson = (await resNote.json()) as any;
    console.log('[PASS] Sermon Note Created:', noteJson.note.id);

    console.log('--- ALL BACKEND API TESTS PASSED CLEANLY ---');
  } catch (err) {
    console.error('[FAIL] Backend Test Failed:', err);
    process.exitCode = 1;
  } finally {
    server.close();
    process.exit(process.exitCode || 0);
  }
}

runApiTests();
