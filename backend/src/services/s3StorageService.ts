import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import fs from 'fs';
import path from 'path';

export interface UploadResult {
  url: string;
  isCloud: boolean;
}

export class S3StorageService {
  private static s3Client: S3Client | null = null;

  private static get bucketName(): string {
    return process.env.R2_BUCKET_NAME || process.env.AWS_S3_BUCKET_NAME || 'lcmaudios-media';
  }

  private static get publicDomain(): string {
    return (
      process.env.R2_PUBLIC_DOMAIN ||
      process.env.CLOUDFRONT_DOMAIN ||
      process.env.AWS_CLOUDFRONT_DOMAIN ||
      ''
    );
  }

  private static get accountId(): string {
    return process.env.R2_ACCOUNT_ID || process.env.CLOUDFLARE_ACCOUNT_ID || '';
  }

  private static get isR2(): boolean {
    return !!S3StorageService.accountId;
  }

  private static getClient(): S3Client | null {
    if (!S3StorageService.s3Client && S3StorageService.isConfigured()) {
      const accessKeyId = process.env.R2_ACCESS_KEY_ID || process.env.AWS_ACCESS_KEY_ID || '';
      const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY || process.env.AWS_SECRET_ACCESS_KEY || '';

      if (S3StorageService.isR2) {
        // Cloudflare R2 S3-Compatible Endpoint
        console.log(`[Storage] Initializing Cloudflare R2 client for account: ${S3StorageService.accountId}`);
        S3StorageService.s3Client = new S3Client({
          region: 'auto',
          endpoint: `https://${S3StorageService.accountId}.r2.cloudflarestorage.com`,
          credentials: {
            accessKeyId,
            secretAccessKey,
          },
        });
      } else {
        // AWS S3 standard
        const region = process.env.AWS_REGION || 'us-east-2';
        console.log(`[Storage] Initializing AWS S3 client in region: ${region}`);
        S3StorageService.s3Client = new S3Client({
          region,
          credentials: {
            accessKeyId,
            secretAccessKey,
          },
        });
      }
    }
    return S3StorageService.s3Client;
  }

  public static isConfigured(): boolean {
    const hasR2 = !!(
      (process.env.R2_ACCOUNT_ID || process.env.CLOUDFLARE_ACCOUNT_ID) &&
      (process.env.R2_ACCESS_KEY_ID || process.env.AWS_ACCESS_KEY_ID) &&
      (process.env.R2_SECRET_ACCESS_KEY || process.env.AWS_SECRET_ACCESS_KEY)
    );
    const hasS3 = !!(
      process.env.AWS_S3_BUCKET_NAME &&
      process.env.AWS_ACCESS_KEY_ID &&
      process.env.AWS_SECRET_ACCESS_KEY
    );
    return hasR2 || hasS3;
  }

  /**
   * Uploads a local file to Cloudflare R2 / AWS S3 (or returns local fallback URL)
   */
  public static async uploadFile(
    localFilePath: string,
    keyPrefix: 'audio' | 'artwork' | 'hls',
    fileName: string,
    fallbackServerUrl: string
  ): Promise<UploadResult> {
    if (!fs.existsSync(localFilePath)) {
      return { url: '', isCloud: false };
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
          if (S3StorageService.publicDomain) {
            const cleanDomain = S3StorageService.publicDomain.replace(/\/$/, '');
            finalUrl = `${cleanDomain.startsWith('http') ? cleanDomain : 'https://' + cleanDomain}/${s3Key}`;
          } else if (S3StorageService.isR2) {
            // Default R2 public bucket URL format
            finalUrl = `https://${S3StorageService.bucketName}.${S3StorageService.accountId}.r2.cloudflarestorage.com/${s3Key}`;
          } else {
            const region = process.env.AWS_REGION || 'us-east-2';
            finalUrl = `https://${S3StorageService.bucketName}.s3.${region}.amazonaws.com/${s3Key}`;
          }

          console.log(`[Storage] ✅ Uploaded ${fileName} to ${S3StorageService.isR2 ? 'Cloudflare R2' : 'AWS S3'} -> ${finalUrl}`);
          return { url: finalUrl, isCloud: true };
        }
      } catch (error) {
        console.error('[Storage] Cloud upload error, falling back to local storage:', error);
      }
    }

    // Local / Render fallback URL
    const localUrl = `${fallbackServerUrl}/uploads/${keyPrefix}/${fileName}`;
    return { url: localUrl, isCloud: false };
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
