export type PaymentStatus = 'UNPAID' | 'PARTIAL' | 'PAID';

export interface CostItem {
  id: string;
  category: string;
  item_name: string;
  estimated_cost: string;
  actual_cost: string | null;
  vendor: string | null;
  payment_status: PaymentStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CategorySummary {
  category: string;
  estimated: string;
  actual: string;
  items: number;
}

export interface CostSummary {
  grand_estimated: string;
  grand_actual: string;
  variance: string;
  by_category: CategorySummary[] | null;
}

export interface CostCreatePayload {
  category: string;
  itemName: string;
  estimatedCost: number;
  actualCost?: number | null;
  vendor?: string | null;
  paymentStatus?: PaymentStatus;
  notes?: string | null;
}

export interface CostUpdatePayload {
  category?: string;
  itemName?: string;
  estimatedCost?: number | null;
  actualCost?: number | null;
  vendor?: string | null;
  paymentStatus?: PaymentStatus;
  notes?: string | null;
}

export const PAYMENT_OPTIONS = [
  { label: 'Unpaid', value: 'UNPAID' },
  { label: 'Partial', value: 'PARTIAL' },
  { label: 'Paid', value: 'PAID' },
];

export const PAYMENT_VARIANT: Record<PaymentStatus, 'destructive' | 'warning' | 'success'> = {
  UNPAID: 'destructive',
  PARTIAL: 'warning',
  PAID: 'success',
};
