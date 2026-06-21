import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(value: number | string | null | undefined): string {
  const n = typeof value === 'string' ? Number(value) : (value ?? 0);
  if (Number.isNaN(n)) return '—';
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'NPR',
    maximumFractionDigits: 0,
  }).format(n);
}

export function formatNumber(value: number | string | null | undefined): string {
  const n = typeof value === 'string' ? Number(value) : (value ?? 0);
  if (Number.isNaN(n)) return '0';
  return new Intl.NumberFormat('en-IN').format(n);
}

export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return '—';
  const d = typeof value === 'string' ? new Date(value) : value;
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}
