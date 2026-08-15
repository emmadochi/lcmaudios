import https from 'https';

export interface PaystackInitResponse {
  status: boolean;
  message: string;
  data?: {
    authorization_url: string;
    access_code: string;
    reference: string;
  };
}

export interface PaystackVerifyResponse {
  status: boolean;
  message: string;
  data?: {
    id: number;
    domain: string;
    status: string;
    reference: string;
    amount: number;
    message: string | null;
    gateway_response: string;
    paid_at: string;
    created_at: string;
    channel: string;
    currency: string;
    ip_address: string;
    customer: {
      id: number;
      first_name?: string;
      last_name?: string;
      email: string;
      customer_code: string;
      phone?: string;
    };
    metadata?: any;
  };
}

export class PaystackService {
  private static get secretKey(): string {
    return process.env.PAYSTACK_SECRET_KEY || 'sk_test_mock_lcm_faith_secret_key_2026';
  }

  public static get publicKey(): string {
    return process.env.PAYSTACK_PUBLIC_KEY || 'pk_test_mock_lcm_faith_public_key_2026';
  }

  /**
   * Initialize a Paystack transaction
   */
  public static async initializeTransaction(params: {
    email: string;
    amountInKobo: number;
    reference: string;
    callbackUrl?: string;
    metadata?: any;
  }): Promise<PaystackInitResponse> {
    const isLiveKey = this.secretKey.startsWith('sk_live_') || (this.secretKey.startsWith('sk_test_') && !this.secretKey.includes('mock'));

    if (!isLiveKey) {
      // Graceful local test mock
      return {
        status: true,
        message: 'Authorization URL created (Mock Test Mode)',
        data: {
          authorization_url: `https://checkout.paystack.com/mock-checkout-${params.reference}`,
          access_code: `mock_acc_${Date.now()}`,
          reference: params.reference,
        },
      };
    }

    return new Promise((resolve, reject) => {
      const data = JSON.stringify({
        email: params.email,
        amount: params.amountInKobo,
        reference: params.reference,
        callback_url: params.callbackUrl,
        metadata: params.metadata,
      });

      const options = {
        hostname: 'api.paystack.co',
        port: 443,
        path: '/transaction/initialize',
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
          'Content-Type': 'application/json',
          'Content-Length': data.length,
        },
      };

      const req = https.request(options, (res) => {
        let responseBody = '';
        res.on('data', (chunk) => {
          responseBody += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(responseBody);
            resolve(parsed);
          } catch (e) {
            reject(new Error('Invalid response from Paystack'));
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.write(data);
      req.end();
    });
  }

  /**
   * Verify a transaction reference with Paystack
   */
  public static async verifyTransaction(reference: string): Promise<PaystackVerifyResponse> {
    const isLiveKey = this.secretKey.startsWith('sk_live_') || (this.secretKey.startsWith('sk_test_') && !this.secretKey.includes('mock'));

    if (!isLiveKey) {
      // Mock test verification
      return {
        status: true,
        message: 'Verification successful (Mock Mode)',
        data: {
          id: Math.floor(Math.random() * 100000),
          domain: 'test',
          status: 'success',
          reference,
          amount: reference.includes('ANNUAL') ? 2400000 : 250000,
          message: null,
          gateway_response: 'Successful',
          paid_at: new Date().toISOString(),
          created_at: new Date().toISOString(),
          channel: 'card',
          currency: 'NGN',
          ip_address: '127.0.0.1',
          customer: {
            id: 101,
            email: 'partner@lcmfaith.org',
            customer_code: 'CUS_mock_123',
          },
        },
      };
    }

    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'api.paystack.co',
        port: 443,
        path: `/transaction/verify/${encodeURIComponent(reference)}`,
        method: 'GET',
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
        },
      };

      const req = https.request(options, (res) => {
        let responseBody = '';
        res.on('data', (chunk) => {
          responseBody += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(responseBody);
            resolve(parsed);
          } catch (e) {
            reject(new Error('Failed to parse Paystack verification response'));
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.end();
    });
  }
}
