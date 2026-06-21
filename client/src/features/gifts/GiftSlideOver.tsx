import { useState } from 'react';
import { Trash2, Gift as GiftIcon, Coins, Package } from 'lucide-react';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate } from '@/lib/utils';
import { GIFT_TYPE_OPTIONS, type GiftType } from './gift.types';
import { useCreateGift, useDeleteGift, useGuestGifts } from './gift.hooks';
import type { Guest } from '../guests/guest.types';

interface Props {
  guest: Guest | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function GiftSlideOver({ guest, open, onOpenChange }: Props) {
  const { data: gifts = [], isLoading } = useGuestGifts(open ? (guest?.id ?? null) : null);
  const createGift = useCreateGift(guest?.id ?? null);
  const deleteGift = useDeleteGift();

  const [giftType, setGiftType] = useState<GiftType>('CASH');
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [remarks, setRemarks] = useState('');

  const totalCash = gifts
    .filter((g) => g.gift_type === 'CASH')
    .reduce((sum, g) => sum + Number(g.amount ?? 0), 0);
  const kindItems = gifts.filter((g) => g.gift_type === 'KIND');

  const handleAdd = async () => {
    if (giftType === 'CASH' && !amount) return;
    if (giftType === 'KIND' && !description.trim()) return;
    await createGift.mutateAsync({
      giftType,
      amount: giftType === 'CASH' ? Number(amount) : null,
      description: giftType === 'KIND' ? description.trim() : null,
      remarks: remarks || null,
    });
    setAmount('');
    setDescription('');
    setRemarks('');
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="overflow-y-auto">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2">
            <GiftIcon className="h-5 w-5 text-primary" />
            Gifts — {guest?.family_name}
          </SheetTitle>
          <SheetDescription>Record cash and in-kind contributions.</SheetDescription>
        </SheetHeader>

        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-lg border bg-secondary/40 p-3">
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Coins className="h-3.5 w-3.5" /> Total Cash
            </div>
            <div className="mt-1 text-lg font-bold">{formatCurrency(totalCash)}</div>
          </div>
          <div className="rounded-lg border bg-secondary/40 p-3">
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Package className="h-3.5 w-3.5" /> In-Kind Items
            </div>
            <div className="mt-1 text-lg font-bold">{kindItems.length}</div>
          </div>
        </div>

        {/* Add gift form */}
        <div className="space-y-2 rounded-lg border p-3">
          <p className="text-sm font-medium">Add a gift</p>
          <Select
            options={GIFT_TYPE_OPTIONS}
            value={giftType}
            onChange={(e) => setGiftType(e.target.value as GiftType)}
          />
          {giftType === 'CASH' ? (
            <Input
              type="number"
              min={0}
              placeholder="Amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          ) : (
            <Input
              placeholder="Item description (e.g. Dinner set)"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          )}
          <Input
            placeholder="Remarks (optional)"
            value={remarks}
            onChange={(e) => setRemarks(e.target.value)}
          />
          <Button className="w-full" onClick={handleAdd} disabled={createGift.isPending}>
            {createGift.isPending ? 'Saving…' : 'Add Gift'}
          </Button>
        </div>

        {/* Gift list */}
        <div className="flex-1 space-y-2">
          <p className="text-sm font-medium">Recorded ({gifts.length})</p>
          {isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
          {!isLoading && gifts.length === 0 && (
            <p className="text-sm text-muted-foreground">No gifts recorded yet.</p>
          )}
          {gifts.map((g) => (
            <div
              key={g.id}
              className="flex items-center justify-between rounded-md border px-3 py-2 text-sm"
            >
              <div>
                <div className="flex items-center gap-2">
                  <Badge variant={g.gift_type === 'CASH' ? 'success' : 'info'}>
                    {g.gift_type === 'CASH' ? 'Cash' : 'In-Kind'}
                  </Badge>
                  <span className="font-medium">
                    {g.gift_type === 'CASH' ? formatCurrency(g.amount) : g.description}
                  </span>
                </div>
                <div className="mt-0.5 text-xs text-muted-foreground">
                  {formatDate(g.received_at)}
                  {g.remarks ? ` · ${g.remarks}` : ''}
                </div>
              </div>
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 text-destructive"
                onClick={() => deleteGift.mutate(g.id)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          ))}
        </div>
      </SheetContent>
    </Sheet>
  );
}
