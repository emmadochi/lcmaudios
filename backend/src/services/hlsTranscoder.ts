import ffmpegInstaller from '@ffmpeg-installer/ffmpeg';
import ffmpeg from 'fluent-ffmpeg';
import path from 'path';
import fs from 'fs';

// Point fluent-ffmpeg at the npm-bundled binary — no system ffmpeg required
ffmpeg.setFfmpegPath(ffmpegInstaller.path);

export interface TranscodeResult {
  success: boolean;
  hlsUrl: string;
  segmentCount: number;
  message: string;
}

export class HlsTranscoder {
  /**
   * Transcode an audio file (.mp3 / .wav / .aac) into an HLS VOD playlist
   * (.m3u8) with 10-second AAC-128k segments (.ts).
   *
   * The npm package @ffmpeg-installer/ffmpeg bundles a pre-built FFmpeg binary
   * so no system-level install is required in dev or on Railway/Render.
   */
  public static async transcodeToHls(
    inputFilePath: string,
    trackId: string,
    hostUrl: string = process.env.API_HOST || 'http://localhost:5000'
  ): Promise<TranscodeResult> {
    if (!fs.existsSync(inputFilePath)) {
      return {
        success: false,
        hlsUrl: '',
        segmentCount: 0,
        message: 'Source audio file does not exist.',
      };
    }

    // Prepare output directory  uploads/hls/<trackId>/
    const hlsBaseDir = path.resolve(__dirname, '../../uploads/hls', trackId);
    if (!fs.existsSync(hlsBaseDir)) {
      fs.mkdirSync(hlsBaseDir, { recursive: true });
    }

    const playlistPath = path.join(hlsBaseDir, 'playlist.m3u8');
    const segmentPattern = path.join(hlsBaseDir, 'segment_%03d.ts');

    return new Promise<TranscodeResult>((resolve) => {
      console.log(`[HLS] Transcoding started → trackId: ${trackId}`);
      console.log(`[HLS] FFmpeg binary: ${ffmpegInstaller.path}`);

      ffmpeg(inputFilePath)
        .audioCodec('aac')
        .audioBitrate('128k')
        .outputOptions([
          '-hls_time 10',
          '-hls_playlist_type vod',
          `-hls_segment_filename ${segmentPattern}`,
        ])
        .output(playlistPath)
        .on('start', (cmd: string) => console.log(`[HLS] Command: ${cmd}`))
        .on('end', () => {
          const files = fs.readdirSync(hlsBaseDir);
          const segments = files.filter((f) => f.endsWith('.ts'));
          const hlsUrl = `${hostUrl}/uploads/hls/${trackId}/playlist.m3u8`;
          console.log(`[HLS] ✅ Done — ${segments.length} segments for ${trackId}`);
          resolve({
            success: true,
            hlsUrl,
            segmentCount: segments.length,
            message: `HLS transcoding completed with ${segments.length} segments.`,
          });
        })
        .on('error', (err: Error) => {
          console.error(`[HLS] ❌ Transcoding error for ${trackId}:`, err.message);
          resolve({
            success: false,
            hlsUrl: '',
            segmentCount: 0,
            message: `Transcoding failed: ${err.message}`,
          });
        })
        .run();
    });
  }

  /**
   * Returns the path to the HLS playlist for a given trackId, or null if
   * the HLS output hasn't been generated yet.
   */
  public static getPlaylistPath(trackId: string): string | null {
    const playlistPath = path.resolve(
      __dirname,
      '../../uploads/hls',
      trackId,
      'playlist.m3u8'
    );
    return fs.existsSync(playlistPath) ? playlistPath : null;
  }
}
