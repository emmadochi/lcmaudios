import { Request, Response } from 'express';
import { PaystackService } from '../services/paystackService';

interface PartnerTransaction {
  reference: string;
  email: string;
  planType: 'monthly' | 'annual';
  amount: number; // in Naira
  currency: string;
  status: 'success' | 'pending' | 'failed';
  channel: string;
  createdAt: string;
  paidAt?: string;
}

// In-memory ledger for active partner subscriptions (can be persisted to PostgreSQL)
const partnerTransactionsLedger: PartnerTransaction[] = [
  {
    reference: 'LCM-PARTNER-ANNUAL-9921',
    email: 'grace.worshipper@lcmfaith.org',
    planType: 'annual',
    amount: 24000,
    currency: 'NGN',
    status: 'success',
    channel: 'card',
    createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
    paidAt: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
  {
    reference: 'LCM-PARTNER-MONTHLY-8812',
    email: 'apostle.media@lcmfaith.org',
    planType: 'monthly',
    amount: 2500,
    currency: 'NGN',
    status: 'success',
    channel: 'bank_transfer',
    createdAt: new Date(Date.now() - 1 * 86400000).toISOString(),
    paidAt: new Date(Date.now() - 1 * 86400000).toISOString(),
  },
];

/**
 * POST /api/v1/payments/initialize
 * Initialize subscription payment with Paystack
 */
export const initializePayment = async (req: Request, res: Response) => {
  try {
    const { email, planType, callbackUrl } = req.body;

    if (!email || !planType) {
      return res.status(400).json({
        success: false,
        message: 'Email and planType (monthly or annual) are required.',
      });
    }

    const isAnnual = planType.toLowerCase() === 'annual';
    const amountInKobo = isAnnual ? 24000 * 100 : 2500 * 100; // ₦24,000 or ₦2,500
    const prefix = isAnnual ? 'LCM-PARTNER-ANNUAL' : 'LCM-PARTNER-MONTHLY';
    const reference = `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const paystackRes = await PaystackService.initializeTransaction({
      email,
      amountInKobo,
      reference,
      callbackUrl,
      metadata: {
        custom_fields: [
          {
            display_name: 'Covenant Partner Tier',
            variable_name: 'covenant_tier',
            value: isAnnual ? 'Annual Covenant Partner' : 'Monthly Seed Partner',
          },
          {
            display_name: 'Ministry Purpose',
            variable_name: 'ministry_purpose',
            value: 'Global Faith Media & Sermon Broadcasts',
          },
        ],
      },
    });

    if (paystackRes.status && paystackRes.data) {
      // Record pending transaction
      partnerTransactionsLedger.unshift({
        reference,
        email,
        planType: isAnnual ? 'annual' : 'monthly',
        amount: isAnnual ? 24000 : 2500,
        currency: 'NGN',
        status: 'pending',
        channel: 'paystack',
        createdAt: new Date().toISOString(),
      });

      return res.status(200).json({
        success: true,
        message: 'Paystack payment initialized successfully.',
        data: {
          authorizationUrl: paystackRes.data.authorization_url,
          accessCode: paystackRes.data.access_code,
          reference: paystackRes.data.reference,
          publicKey: PaystackService.publicKey,
          amount: isAnnual ? 24000 : 2500,
          currency: 'NGN',
          planType: isAnnual ? 'annual' : 'monthly',
        },
      });
    } else {
      return res.status(400).json({
        success: false,
        message: paystackRes.message || 'Unable to initialize transaction with Paystack.',
      });
    }
  } catch (error: any) {
    console.error('[PaymentController] Error initializing payment:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error initializing payment.',
    });
  }
};

/**
 * GET /api/v1/payments/verify/:reference
 * Verify payment with Paystack and activate covenant partner status
 */
export const verifyPayment = async (req: Request, res: Response) => {
  try {
    const { reference } = req.params;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: 'Transaction reference is required.',
      });
    }

    const paystackRes = await PaystackService.verifyTransaction(reference);

    if (paystackRes.status && paystackRes.data && paystackRes.data.status === 'success') {
      const isAnnual = reference.includes('ANNUAL') || paystackRes.data.amount >= 2000000;
      const planType: 'monthly' | 'annual' = isAnnual ? 'annual' : 'monthly';
      const amount = paystackRes.data.amount / 100;

      // Update or insert into ledger
      const existingIdx = partnerTransactionsLedger.findIndex((t) => t.reference === reference);
      if (existingIdx !== -1) {
        partnerTransactionsLedger[existingIdx].status = 'success';
        partnerTransactionsLedger[existingIdx].paidAt = paystackRes.data.paid_at || new Date().toISOString();
        partnerTransactionsLedger[existingIdx].channel = paystackRes.data.channel || 'card';
      } else {
        partnerTransactionsLedger.unshift({
          reference,
          email: paystackRes.data.customer?.email || 'partner@lcmfaith.org',
          planType,
          amount,
          currency: 'NGN',
          status: 'success',
          channel: paystackRes.data.channel || 'card',
          createdAt: paystackRes.data.created_at || new Date().toISOString(),
          paidAt: paystackRes.data.paid_at || new Date().toISOString(),
        });
      }

      // Calculate partnership expiration
      const startDate = new Date();
      const expirationDate = new Date();
      if (isAnnual) {
        expirationDate.setFullYear(startDate.getFullYear() + 1);
      } else {
        expirationDate.setMonth(startDate.getMonth() + 1);
      }

      return res.status(200).json({
        success: true,
        message: '🎉 Payment verified successfully. Covenant Partner tier activated.',
        data: {
          reference,
          planType,
          amount,
          currency: 'NGN',
          status: 'active',
          startDate: startDate.toISOString(),
          expirationDate: expirationDate.toISOString(),
          receiptNumber: `LCM-REC-${Date.now().toString().slice(-6)}`,
        },
      });
    } else {
      return res.status(400).json({
        success: false,
        message: paystackRes.message || 'Payment verification failed or status is not success.',
      });
    }
  } catch (error: any) {
    console.error('[PaymentController] Error verifying payment:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Internal server error verifying payment.',
    });
  }
};

/**
 * POST /api/v1/payments/webhook
 * Paystack Webhook Handler
 */
export const handleWebhook = async (req: Request, res: Response) => {
  try {
    const event = req.body;
    console.log(`[Paystack Webhook] Received event: ${event?.event}`);

    if (event?.event === 'charge.success' && event?.data?.reference) {
      const ref = event.data.reference;
      const existingIdx = partnerTransactionsLedger.findIndex((t) => t.reference === ref);
      if (existingIdx !== -1) {
        partnerTransactionsLedger[existingIdx].status = 'success';
        partnerTransactionsLedger[existingIdx].paidAt = event.data.paid_at;
      }
    }

    // Always respond 200 OK to Paystack
    return res.status(200).json({ received: true });
  } catch (error: any) {
    console.error('[PaymentController] Error in webhook:', error);
    return res.status(200).json({ received: true });
  }
};

/**
 * GET /api/v1/admin/partners/ledger
 * Admin endpoint to view partnership ledger and analytics
 */
export const getPartnerLedgerAdmin = async (req: Request, res: Response) => {
  try {
    const successfulTx = partnerTransactionsLedger.filter((t) => t.status === 'success');
    const totalAmount = successfulTx.reduce((acc, curr) => acc + curr.amount, 0);

    return res.status(200).json({
      success: true,
      data: {
        totalPartners: successfulTx.length,
        totalRevenueNgn: totalAmount,
        activeMonthly: successfulTx.filter((t) => t.planType === 'monthly').length,
        activeAnnual: successfulTx.filter((t) => t.planType === 'annual').length,
        transactions: partnerTransactionsLedger,
      },
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Error fetching partner ledger.',
    });
  }
};
