import { Users, Gift, Wallet, Coins, UserCheck } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn, formatCurrency, formatDate, formatNumber } from '@/lib/utils';
import { useGuestSummary } from '../guests/guest.hooks';
import { useGiftSummary, useGifts } from '../gifts/gift.hooks';
import { useCostSummary } from '../costs/cost.hooks';
import { useEventContext } from '@/context/EventContext';

function StatCard({
  icon: Icon,
  label,
  value,
  sub,
  tint,
}: {
  icon: typeof Users;
  label: string;
  value: string;
  sub?: string;
  tint: string;
}) {
  return (
    <Card>
      <CardContent className="p-5">
        <div className="flex items-center justify-between">
          <div className="text-sm text-muted-foreground">{label}</div>
          <div className={cn('rounded-full p-2', tint)}>
            <Icon className="h-5 w-5" />
          </div>
        </div>
        <div className="mt-2 text-3xl font-bold">{value}</div>
        {sub && <div className="mt-1 text-xs text-muted-foreground">{sub}</div>}
      </CardContent>
    </Card>
  );
}

export function DashboardPage() {
  const { eventId, canViewCosts } = useEventContext();
  const { data: guests } = useGuestSummary(eventId);
  const { data: giftSummary } = useGiftSummary(eventId);
  // Only OWNER/LEADER may read costs; viewers simply don't see the card.
  const { data: costSummary } = useCostSummary(eventId, canViewCosts);
  const { data: recentGifts = [] } = useGifts(eventId);

  const estimated = Number(costSummary?.grand_estimated ?? 0);
  const actual = Number(costSummary?.grand_actual ?? 0);
  const budgetUsed = estimated > 0 ? Math.round((actual / estimated) * 100) : 0;

  return (
    <div>
      <div className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard icon={Users} label="Families" value={formatNumber(guests?.total_families ?? 0)} sub={`${formatNumber(guests?.total_estimated_attendees ?? 0)} estimated attendees`} tint="bg-rose-100 text-rose-700" />
        <StatCard icon={UserCheck} label="Confirmed" value={formatNumber(guests?.total_confirmed_attendees ?? 0)} sub={`${formatNumber(guests?.rsvp_confirmed ?? 0)} families confirmed`} tint="bg-emerald-100 text-emerald-700" />
        <StatCard icon={Coins} label="Cash Gifts" value={formatCurrency(giftSummary?.total_cash ?? 0)} sub={`${formatNumber(giftSummary?.total_gifts ?? 0)} gifts recorded`} tint="bg-amber-100 text-amber-700" />
        {canViewCosts && (
          <StatCard icon={Wallet} label="Budget Used" value={`${budgetUsed}%`} sub={`${formatCurrency(actual)} of ${formatCurrency(estimated)}`} tint="bg-sky-100 text-sky-700" />
        )}
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Recent Gifts</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {recentGifts.length === 0 && <p className="text-sm text-muted-foreground">No gifts yet.</p>}
          {recentGifts.slice(0, 6).map((g) => (
            <div key={g.id} className="flex items-start gap-3">
              <div className="mt-0.5 rounded-full bg-amber-100 p-1.5">
                <Gift className="h-3.5 w-3.5 text-amber-700" />
              </div>
              <div className="flex-1 text-sm">
                <div>
                  <span className="font-medium">{g.family_name}</span> gave{' '}
                  {g.gift_type === 'CASH' ? formatCurrency(g.amount) : g.description}
                </div>
                <div className="text-xs text-muted-foreground">{formatDate(g.received_at)}</div>
              </div>
              <Badge variant={g.gift_type === 'CASH' ? 'success' : 'info'}>
                {g.gift_type === 'CASH' ? 'Cash' : 'Kind'}
              </Badge>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
