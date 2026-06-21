import { Coins, Package, Gift as GiftIcon } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate } from '@/lib/utils';
import { useGifts, useGiftSummary } from './gift.hooks';

function StatCard({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Coins;
  label: string;
  value: string | number;
}) {
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-5">
        <div className="rounded-full bg-primary/10 p-3">
          <Icon className="h-6 w-6 text-primary" />
        </div>
        <div>
          <div className="text-sm text-muted-foreground">{label}</div>
          <div className="text-2xl font-bold">{value}</div>
        </div>
      </CardContent>
    </Card>
  );
}

export function GiftsPage() {
  const { data: gifts = [], isLoading } = useGifts();
  const { data: summary } = useGiftSummary();

  return (
    <div>
      <PageHeader
        title="Gifts & Contributions"
        description="All cash and in-kind contributions received."
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <StatCard icon={Coins} label="Total Cash Collected" value={formatCurrency(summary?.total_cash ?? 0)} />
        <StatCard icon={Package} label="In-Kind Items" value={summary?.total_kind_items ?? 0} />
        <StatCard icon={GiftIcon} label="Total Gifts Recorded" value={summary?.total_gifts ?? 0} />
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-secondary text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 text-left">Family</th>
                  <th className="px-4 py-3 text-left">Type</th>
                  <th className="px-4 py-3 text-left">Amount / Item</th>
                  <th className="px-4 py-3 text-left">Received</th>
                  <th className="px-4 py-3 text-left">Remarks</th>
                </tr>
              </thead>
              <tbody>
                {isLoading && (
                  <tr>
                    <td colSpan={5} className="px-4 py-6 text-center text-muted-foreground">
                      Loading…
                    </td>
                  </tr>
                )}
                {!isLoading && gifts.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-6 text-center text-muted-foreground">
                      No gifts recorded yet. Open a guest's Gifts panel to add one.
                    </td>
                  </tr>
                )}
                {gifts.map((g) => (
                  <tr key={g.id} className="border-b last:border-0 hover:bg-secondary/40">
                    <td className="px-4 py-3 font-medium">{g.family_name}</td>
                    <td className="px-4 py-3">
                      <Badge variant={g.gift_type === 'CASH' ? 'success' : 'info'}>
                        {g.gift_type === 'CASH' ? 'Cash' : 'In-Kind'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      {g.gift_type === 'CASH' ? formatCurrency(g.amount) : g.description}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{formatDate(g.received_at)}</td>
                    <td className="px-4 py-3 text-muted-foreground">{g.remarks ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
