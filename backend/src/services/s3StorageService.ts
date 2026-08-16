import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import fs from 'fs';
import path from 'path';

export interface UploadResult {
  url: string;
  isS3: boolean;
}

export class S3StorageService {
  private static s3Client: S3Client | null = null;
  private static get bucketName(): string {
    return process.env.AWS_S3_BUCKET_NAME || 'lcmaudios-media';
  }
  private static get cloudFrontDomain(): string {
    return process.env.CLOUDFRONT_DOMAIN || process.env.AWS_CLOUDFRONT_DOMAIN || '';
  }
  private static get region(): string {
    return process.env.AWS_REGION || 'us-east-2';
  }

  private static getClient(): S3Client | null {
    if (!S3StorageService.s3Client && S3StorageService.isConfigured()) {
      S3StorageService.s3Client = new S3Client({
        region: S3StorageService.region,
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
        },
      });
    }
    return S3StorageService.s3Client;
  }

  public static isConfigured(): boolean {
    return !!(
      process.env.AWS_S3_BUCKET_NAME &&
      process.env.AWS_ACCESS_KEY_ID &&
      process.env.AWS_SECRET_ACCESS_KEY
    );
  }

  /**
   * Uploads a local file to AWS S3 (or returns local fallback URL)
   */
  public static async uploadFile(
    localFilePath: string,
    keyPrefix: 'audio' | 'artwork' | 'hls',
    fileName: string,
    fallbackServerUrl: string
  ): Promise<UploadResult> {
    if (!fs.existsSync(localFilePath)) {
      return { url: '', isS3: false };
    }

    if (S3StorageService.isConfigured()) {
      try {
        const client = S3StorageService.getClient();
        if (client) {
          const s3Key = `${keyPrefix}/${fileName}`;
          const fileStream = fs.createReadStream(localFilePath);
          const contentType = S3StorageService.getContentType(fileName);

          const command = new PutObjectCommand({
            Bucket: S3StorageService.bucketName,
            Key: s3Key,
            Body: fileStream,
            ContentType: contentType,
            CacheControl: 'public, max-age=31536000, immutable',
          });

          await client.send(command);

          let finalUrl: string;
          if (S3StorageService.cloudFrontDomain) {
            const cleanDomain = S3StorageService.cloudFrontDomain.replace(/\/$/, '');
            finalUrl = `${cleanDomain.startsWith('http') ? cleanDomain : 'https://' + cleanDomain}/${s3Key}`;
          } else {
            finalUrl = `https://${S3StorageService.bucketName}.s3.${S3StorageService.region}.amazonaws.com/${s3Key}`;
          }

          console.log(`[AWS S3] ✅ Uploaded ${fileName} to S3 bucket: ${S3StorageService.bucketName} -> ${finalUrl}`);
          return { url: finalUrl, isS3: true };
        }
      } catch (error) {
        console.error('[AWS S3] S3 upload error, using local fallback:', error);
      }
    }

    // Local / Render fallback URL
    const localUrl = `${fallbackServerUrl}/uploads/${keyPrefix}/${fileName}`;
    return { url: localUrl, isS3: false };
  }

  private static getContentType(fileName: string): string {
    const ext = path.extname(fileName).toLowerCase();
    switch (ext) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.flac':
        return 'audio/flac';
      case '.m4a':
      case '.aac':
        return 'audio/aac';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.m3u8':
        return 'application/vnd.apple.mpegurl';
      case '.ts':
        return 'video/mp2t';
      default:
        return 'application/octet-stream';
    }
  }
}
