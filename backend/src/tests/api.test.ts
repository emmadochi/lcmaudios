process.env.NODE_ENV = 'test';

import app from '../server';
import http from 'http';

async function runFullCrudVerification() {
  console.log('====================================================');
  console.log('  LCM AUDIOS BACKEND: FULL CRUD COMPREHENSIVE TEST  ');
  console.log('====================================================\n');

  const server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(5098, resolve));
  const BASE_URL = 'http://localhost:5098/api/v1';

  let passedTests = 0;
  let failedTests = 0;

  async function assertTest(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  ✅ [PASS] ${name}`);
      passedTests++;
    } catch (err: any) {
      console.error(`  ❌ [FAIL] ${name}:`, err.message || err);
      failedTests++;
    }
  }

  try {
    // ─── 1. HEALTH & CONNECTIVITY ──────────────────────────────────────────
    console.log('🔍 1. HEALTH & SYSTEM CHECKS');
    await assertTest('Health check endpoint responds online', async () => {
      const res = await fetch('http://localhost:5098/health');
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.status !== 'online') throw new Error(`Unexpected status: ${data.status}`);
    });

    // ─── 2. AUTHENTICATION & USER MANAGEMENT ──────────────────────────────
    console.log('\n👤 2. AUTHENTICATION & DEVOTEE USERS CRUD');
    const testEmail = `worshipper_${Date.now()}@lcmfaith.org`;
    let userToken = '';
    let userId = '';

    await assertTest('Register new devotee user (CREATE User)', async () => {
      const res = await fetch(`${BASE_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: testEmail,
          password: 'Password123!',
          fullName: 'Brother David O.',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 201 || !data.token) throw new Error(data.error || 'No token returned');
      userToken = data.token;
      userId = data.user.id;
    });

    await assertTest('Login with credentials (READ / AUTH User)', async () => {
      const res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: testEmail,
          password: 'Password123!',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || !data.token) throw new Error(data.error || 'Login failed');
    });

    await assertTest('Fetch authenticated user profile (READ User Profile)', async () => {
      const res = await fetch(`${BASE_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${userToken}` },
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.user.email !== testEmail.toLowerCase()) {
        throw new Error('User profile mismatch');
      }
    });

    // ─── 3. MINISTERS & PREACHERS CRUD ─────────────────────────────────────
    console.log('\n🎙️ 3. MINISTERS & PREACHERS CRUD OPERATIONS');
    let testMinisterId = '';

    await assertTest('CREATE Minister (POST /admin/ministers)', async () => {
      const res = await fetch(`${BASE_URL}/admin/ministers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Pastor Emmanuel Adeleke',
          role: 'Guest Apostolic Minister',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
          bio: 'Preaching deep prophetic revelation and prayer apostolic dimensions.',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 201 || !data.minister?.id) throw new Error(data.error || 'Failed to create minister');
      testMinisterId = data.minister.id;
    });

    await assertTest('READ All Ministers (GET /ministers)', async () => {
      const res = await fetch(`${BASE_URL}/ministers`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !Array.isArray(data.ministers) || data.ministers.length === 0) {
        throw new Error('No ministers returned');
      }
      const found = data.ministers.find((m: any) => m.id === testMinisterId);
      if (!found) throw new Error('Created minister not in list');
    });

    await assertTest('READ Single Minister by ID (GET /ministers/:id)', async () => {
      const res = await fetch(`${BASE_URL}/ministers/${testMinisterId}`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.minister.name !== 'Pastor Emmanuel Adeleke') {
        throw new Error('Minister data mismatch');
      }
    });

    await assertTest('UPDATE Minister details (PUT /admin/ministers/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/ministers/${testMinisterId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Rev. Emmanuel Adeleke (Senior Pastor)',
          role: 'Dean of Prayer & Apostolic Impartation',
          bio: 'Updated bio description for minister.',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.minister.name !== 'Rev. Emmanuel Adeleke (Senior Pastor)') {
        throw new Error(data.error || 'Minister update failed');
      }
    });

    await assertTest('DELETE Minister (DELETE /admin/ministers/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/ministers/${testMinisterId}`, {
        method: 'DELETE',
      });
      if (res.status !== 200) throw new Error('Delete minister failed');

      // Verify minister is no longer returned
      const checkRes = await fetch(`${BASE_URL}/ministers/${testMinisterId}`);
      if (checkRes.status !== 404) throw new Error('Deleted minister still accessible');
    });

    // ─── 4. INTENT CATEGORIES CRUD ─────────────────────────────────────────
    console.log('\n🏷️ 4. INTENT CATEGORIES CRUD OPERATIONS');
    let testCategoryId = '';
    const uniqueCatKey = `propheticWorship_${Date.now()}`;

    await assertTest('CREATE Intent Category (POST /admin/categories)', async () => {
      const res = await fetch(`${BASE_URL}/admin/categories`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Prophetic Night Vigil',
          categoryKey: uniqueCatKey,
          description: 'Midnight warfare chants and apostolic prayers',
          accentColor: '#9333EA',
          icon: 'shield_rounded',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 201 || !data.category?.id) throw new Error(data.error || 'Failed to create category');
      testCategoryId = data.category.id;
    });

    await assertTest('READ All Intent Categories (GET /categories)', async () => {
      const res = await fetch(`${BASE_URL}/categories`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !Array.isArray(data.categories)) throw new Error('Categories list failed');
      const found = data.categories.find((c: any) => c.categoryKey === uniqueCatKey);
      if (!found) throw new Error('Created category not found in catalog');
    });

    await assertTest('UPDATE Intent Category (PUT /admin/categories/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/categories/${testCategoryId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Prophetic & Apostolic Fire',
          accentColor: '#EF4444',
          description: 'Updated high-energy warfare chants',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.category.title !== 'Prophetic & Apostolic Fire') {
        throw new Error('Update category failed');
      }
    });

    await assertTest('DELETE Intent Category (DELETE /admin/categories/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/categories/${testCategoryId}`, {
        method: 'DELETE',
      });
      if (res.status !== 200) throw new Error('Delete category failed');

      const checkRes = await fetch(`${BASE_URL}/categories`);
      const checkData = (await checkRes.json()) as any;
      const found = checkData.categories.find((c: any) => c.id === testCategoryId);
      if (found) throw new Error('Deleted category still exists');
    });

    // ─── 5. TRACKS & MEDIA CATALOG CRUD ────────────────────────────────────
    console.log('\n🎵 5. AUDIO TRACKS & SERMON MEDIA CRUD OPERATIONS & PREMIUM ACCESS TIER');
    let testTrackId = '';

    await assertTest('CREATE Premium Track with string value isPremium="true" (POST /admin/tracks)', async () => {
      const res = await fetch(`${BASE_URL}/admin/tracks`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Fresh Anointing & Grace Release',
          artist: 'Pastor Martins Omonua',
          albumArtUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          duration: 380,
          subgenre: 'Prophetic Impartation',
          intentCategory: 'morningDevotion',
          mediaType: 'sermon',
          isPremium: 'true', // Test HTML select string value
          lyrics: [
            { timestampSeconds: 0, text: 'Lord we welcome your glorious presence.' },
            { timestampSeconds: 15.5, text: 'Let your power fall upon this sanctuary.' },
            { timestampSeconds: 32.0, text: 'The Lord is our shield and our buckler.' },
          ],
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 201 || !data.track?.id) throw new Error(data.error || 'Failed to create track');
      if (data.track.isPremium !== true) throw new Error('isPremium="true" string did not parse to boolean true');
      testTrackId = data.track.id;
    });

    await assertTest('READ Single Track (GET /tracks/:id) and verify Premium Flag', async () => {
      const res = await fetch(`${BASE_URL}/tracks/${testTrackId}`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.track.title !== 'Fresh Anointing & Grace Release') {
        throw new Error('Track title mismatch');
      }
      if (data.track.isPremium !== true) throw new Error('isPremium flag was not persisted as true in catalog');
    });

    await assertTest('READ Catalog List (GET /tracks) and verify Access Tier', async () => {
      const res = await fetch(`${BASE_URL}/tracks`);
      const data = (await res.json()) as any;
      const found = data.tracks.find((t: any) => t.id === testTrackId);
      if (!found) throw new Error('Newly created track not in catalog list');
      if (found.isPremium !== true) throw new Error('Catalog list item isPremium is not true');
    });

    await assertTest('QUICK TOGGLE Access Tier to Free: PUT /admin/tracks/:id with only { isPremium: false }', async () => {
      const res = await fetch(`${BASE_URL}/admin/tracks/${testTrackId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isPremium: false }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200) throw new Error('Quick toggle failed');
      if (data.track.isPremium !== false) throw new Error('Quick toggle did not set isPremium to false');
      // Ensure title and artist were not lost/wiped by partial update
      if (data.track.title !== 'Fresh Anointing & Grace Release' || data.track.artist !== 'Pastor Martins Omonua') {
        throw new Error('Partial update destroyed title/artist metadata');
      }
    });

    await assertTest('QUICK TOGGLE Access Tier to Locked: PUT /admin/tracks/:id with only { isPremium: true }', async () => {
      const res = await fetch(`${BASE_URL}/admin/tracks/${testTrackId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isPremium: true }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200) throw new Error('Quick toggle to locked failed');
      if (data.track.isPremium !== true) throw new Error('Quick toggle did not set isPremium to true');
      if (!data.track.title || !data.track.artist) throw new Error('Metadata lost during lock toggle');
    });

    await assertTest('READ Track Synchronized Lyrics (GET /tracks/:id/lyrics)', async () => {
      const res = await fetch(`${BASE_URL}/tracks/${testTrackId}/lyrics`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !Array.isArray(data.lyrics) || data.lyrics.length !== 3) {
        throw new Error('Lyrics count mismatch');
      }
    });

    await assertTest('UPDATE Full Track Metadata (PUT /admin/tracks/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/tracks/${testTrackId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Fresh Anointing & Divine Grace (Extended Version)',
          isPremium: false,
          subgenre: 'Apostolic Revival',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || data.track.title !== 'Fresh Anointing & Divine Grace (Extended Version)') {
        throw new Error('Track update failed');
      }
      if (data.track.isPremium !== false) throw new Error('isPremium toggle failed');
    });

    await assertTest('DELETE Track (DELETE /admin/tracks/:id)', async () => {
      const res = await fetch(`${BASE_URL}/admin/tracks/${testTrackId}`, {
        method: 'DELETE',
      });
      if (res.status !== 200) throw new Error('Delete track failed');

      const checkRes = await fetch(`${BASE_URL}/tracks/${testTrackId}`);
      if (checkRes.status !== 404) throw new Error('Deleted track still accessible');
    });

    // ─── 6. SERMON NOTES CRUD ──────────────────────────────────────────────
    console.log('\n📝 6. SERMON NOTES & DEVOTEE STUDY CRUD');
    let testNoteId = '';

    await assertTest('CREATE Sermon Note (POST /notes)', async () => {
      const res = await fetch(`${BASE_URL}/notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          trackId: 'track_1',
          userId: userId,
          timestampSeconds: 120.0,
          noteText: 'Anointed word on divine transformation and faith.',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 201 || !data.note?.id) throw new Error(data.error || 'Failed to create note');
      testNoteId = data.note.id;
    });

    await assertTest('READ Devotee Sermon Notes (GET /notes?userId=...)', async () => {
      const res = await fetch(`${BASE_URL}/notes?userId=${userId}`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !Array.isArray(data.notes) || data.notes.length === 0) {
        throw new Error('No notes returned');
      }
    });

    // ─── 7. ANALYTICS & PAYSTACK PARTNER LEDGER ─────────────────────────────
    console.log('\n📊 7. ANALYTICS & COVENANT PARTNER LEDGER');
    await assertTest('READ Admin Analytics Summary (GET /admin/analytics)', async () => {
      const res = await fetch(`${BASE_URL}/admin/analytics`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !data.analytics) throw new Error('Analytics failed');
      if (typeof data.analytics.totalStreams !== 'number') throw new Error('Invalid totalStreams');
    });

    await assertTest('READ Covenant Partner Ledger (GET /admin/partners/ledger)', async () => {
      const res = await fetch(`${BASE_URL}/admin/partners/ledger`);
      const data = (await res.json()) as any;
      if (res.status !== 200 || !data.success || !data.data) throw new Error('Ledger fetch failed');
    });

    await assertTest('INITIALIZE Paystack Partnership Transaction (POST /payments/initialize)', async () => {
      const res = await fetch(`${BASE_URL}/payments/initialize`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'donor.partner@lcmfaith.org',
          phone: '+2348012345678',
          planType: 'monthly',
        }),
      });
      const data = (await res.json()) as any;
      if (res.status !== 200 || !data.data?.reference) throw new Error(data.message || 'Payment init failed');
    });

  } catch (err) {
    console.error('[CRITICAL] Suite error:', err);
  } finally {
    server.close();
    console.log('\n====================================================');
    console.log(`  CRUD VERIFICATION SUMMARY: ${passedTests} PASSED / ${failedTests} FAILED  `);
    console.log('====================================================\n');
    if (failedTests > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  }
}

runFullCrudVerification();
