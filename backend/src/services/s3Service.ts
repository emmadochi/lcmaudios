import { S3Client, PutObjectCommand, ObjectCannedACL } from '@aws-sdk/client-s3';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

export class S3Service {
  private static s3Client: S3Client | null = null;
  private static bucketName: string = process.env.AWS_S3_BUCKET_NAME || 'lcmaudios-media';
  private static cloudfrontDomain: string = process.env.AWS_CLOUDFRONT_DOMAIN || '';
  private static region: string = process.env.AWS_REGION || 'us-east-1';

  private static getClient(): S3Client | null {
    if (this.s3Client) return this.s3Client;

    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (accessKeyId && secretAccessKey) {
      try {
        this.s3Client = new S3Client({
          region: this.region,
          credentials: {
            accessKeyId,
            secretAccessKey,
          },
        });
        console.log(`[AWS S3] Initialized S3 Client for bucket: ${this.bucketName} (${this.region})`);
        return this.s3Client;
      } catch (err) {
        console.error('[AWS S3] Initialization error:', err);
        return null;
      }
    }

    return null;
  }

  /**
   * Uploads a file buffer or local file to Amazon S3
   * @param localFilePath Path to the file on local disk
   * @param s3Key Target S3 path / filename (e.g. 'audio/sermon_123.mp3')
   * @param contentType MIME type (e.g. 'audio/mpeg', 'image/jpeg')
   * @returns Public CloudFront or S3 URL
   */
  public static async uploadFile(
    localFilePath: string,
    s3Key: string,
    contentType: string
  ): Promise<string | null> {
    const client = this.getClient();

    if (!client) {
      console.log('[AWS S3] AWS credentials not set; serving from local server upload path.');
      return null;
    }

    try {
      const fileStream = fs.createReadStream(localFilePath);
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: s3Key,
        Body: fileStream,
        ContentType: contentType,
      });

      await client.send(command);

      // Return CloudFront URL if configured, otherwise standard S3 virtual hosted URL
      if (this.cloudfrontDomain) {
        const domain = this.cloudfrontDomain.replace(/^https?:\/\//, '').replace(/\/$/, '');
        return `https://${domain}/${s3Key}`;
      }

      return `https://${this.bucketName}.s3.${this.region}.amazonaws.com/${s3Key}`;
    } catch (error) {
      console.error(`[AWS S3] Failed to upload ${s3Key} to S3:`, error);
      return null;
    }
  }

  /**
   * Uploads an in-memory buffer directly to Amazon S3
   */
  public static async uploadBuffer(
    buffer: Buffer,
    s3Key: string,
    contentType: string
  ): Promise<string | null> {
    const client = this.getClient();

    if (!client) {
      return null;
    }

    try {
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: s3Key,
        Body: buffer,
        ContentType: contentType,
      });

      await client.send(command);

      if (this.cloudfrontDomain) {
        const domain = this.cloudfrontDomain.replace(/^https?:\/\//, '').replace(/\/$/, '');
        return `https://${domain}/${s3Key}`;
      }

      return `https://${this.bucketName}.s3.${this.region}.amazonaws.com/${s3Key}`;
    } catch (error) {
      console.error(`[AWS S3] Failed to upload buffer ${s3Key} to S3:`, error);
      return null;
    }
  }
}
