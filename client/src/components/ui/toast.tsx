import * as React from 'react';
import { CheckCircle2, XCircle, Info } from 'lucide-react';
import { cn } from '@/lib/utils';

type ToastVariant = 'success' | 'error' | 'info';
interface Toast {
  id: number;
  message: string;
  variant: ToastVariant;
}

// Minimal external store so toast() can be called from anywhere (mutations etc.).
let toasts: Toast[] = [];
const listeners = new Set<() => void>();
let nextId = 1;

function emit() {
  listeners.forEach((l) => l());
}

export function toast(message: string, variant: ToastVariant = 'info') {
  const id = nextId++;
  toasts = [...toasts, { id, message, variant }];
  emit();
  setTimeout(() => {
    toasts = toasts.filter((t) => t.id !== id);
    emit();
  }, 3500);
}

const icons = {
  success: <CheckCircle2 className="h-4 w-4 text-emerald-600" />,
  error: <XCircle className="h-4 w-4 text-red-600" />,
  info: <Info className="h-4 w-4 text-sky-600" />,
};

export function Toaster() {
  const snapshot = React.useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => toasts,
    () => toasts,
  );

  return (
    <div className="fixed bottom-4 right-4 z-[100] flex w-80 flex-col gap-2">
      {snapshot.map((t) => (
        <div
          key={t.id}
          className={cn(
            'flex items-center gap-3 rounded-md border bg-card px-4 py-3 text-sm shadow-lg',
          )}
        >
          {icons[t.variant]}
          <span className="text-card-foreground">{t.message}</span>
        </div>
      ))}
    </div>
  );
}
