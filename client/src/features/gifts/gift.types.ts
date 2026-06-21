export type GiftType = 'CASH' | 'KIND';

export interface Gift {
  id: string;
  guest_id: string;
  gift_type: GiftType;
  amount: string | null;
  description: string | null;
  received_at: string;
  remarks: string | null;
  family_name: string;
  created_at: string;
  updated_at: string;
}

export interface GiftSummary {
  total_cash: string;
  total_kind_items: number;
  total_gifts: number;
}

export interface GiftCreatePayload {
  giftType: GiftType;
  amount?: number | null;
  description?: string | null;
  receivedAt?: string;
  remarks?: string | null;
}

export const GIFT_TYPE_OPTIONS = [
  { label: 'Cash', value: 'CASH' },
  { label: 'In-Kind', value: 'KIND' },
];
