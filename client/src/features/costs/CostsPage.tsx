import { useMemo, useState } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Legend,
  CartesianGrid,
} from 'recharts';
import { Plus, Trash2, TrendingDown, TrendingUp, Wallet } from 'lucide-react';
import { PageHeader } from '@/components/layout/PageHeader';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { cn, formatCurrency } from '@/lib/utils';
import {
  PAYMENT_OPTIONS,
  PAYMENT_VARIANT,
  type CostItem,
  type PaymentStatus,
} from './cost.types';
import { useCosts, useCostSummary, useCreateCost, useDeleteCost, useUpdateCost } from './cost.hooks';

function EditableCostCell({
  item,
  field,
}: {
  item: CostItem;
  field: 'estimated_cost' | 'actual_cost';
}) {
  const updateCost = useUpdateCost();
  const initial = item[field] ?? '';
  const [value, setValue] = useState(String(initial));

  const commit = () => {
    const current = String(item[field] ?? '');
    if (value === current) return;
    const num = value === '' ? null : Number(value);
    const payloadKey = field === 'estimated_cost' ? 'estimatedCost' : 'actualCost';
    updateCost.mutate({ id: item.id, payload: { [payloadKey]: num } });
  };

  return (
    <Input
      type="number"
      min={0}
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onBlur={commit}
      onKeyDown={(e) => e.key === 'Enter' && (e.target as HTMLInputElement).blur()}
      className="h-8 w-28 border-transparent bg-transparent text-right hover:border-input"
    />
  );
}

const emptyRow = {
  category: '',
  itemName: '',
  estimatedCost: '',
  vendor: '',
};

export function CostsPage() {
  const { data: items = [], isLoading } = useCosts();
  const { data: summary } = useCostSummary();
  const createCost = useCreateCost();
  const updateCost = useUpdateCost();
  const deleteCost = useDeleteCost();
  const [newRow, setNewRow] = useState(emptyRow);

  const grouped = useMemo(() => {
    const map = new Map<string, CostItem[]>();
    for (const it of items) {
      if (!map.has(it.category)) map.set(it.category, []);
      map.get(it.category)!.push(it);
    }
    return Array.from(map.entries());
  }, [items]);

  const grandEstimated = Number(summary?.grand_estimated ?? 0);
  const grandActual = Number(summary?.grand_actual ?? 0);
  const variance = Number(summary?.variance ?? 0);
  const utilization = grandEstimated > 0 ? Math.min((grandActual / grandEstimated) * 100, 100) : 0;
  const overBudget = variance < 0;

  const chartData = (summary?.by_category ?? []).map((c) => ({
    category: c.category,
    Estimated: Number(c.estimated),
    Actual: Number(c.actual),
  }));

  const handleAdd = async () => {
    if (!newRow.category.trim() || !newRow.itemName.trim()) return;
    await createCost.mutateAsync({
      category: newRow.category.trim(),
      itemName: newRow.itemName.trim(),
      estimatedCost: Number(newRow.estimatedCost) || 0,
      vendor: newRow.vendor || null,
    });
    setNewRow(emptyRow);
  };

  return (
    <div>
      <PageHeader title="Cost Tracker" description="Estimated vs actual budget by category." />

      {/* Summary cards */}
      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="flex items-center gap-4 p-5">
            <div className="rounded-full bg-sky-100 p-3">
              <Wallet className="h-6 w-6 text-sky-700" />
            </div>
            <div>
              <div className="text-sm text-muted-foreground">Total Estimated</div>
              <div className="text-2xl font-bold">{formatCurrency(grandEstimated)}</div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="flex items-center gap-4 p-5">
            <div className="rounded-full bg-emerald-100 p-3">
              <Wallet className="h-6 w-6 text-emerald-700" />
            </div>
            <div>
              <div className="text-sm text-muted-foreground">Total Actual</div>
              <div className="text-2xl font-bold">{formatCurrency(grandActual)}</div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="flex items-center gap-4 p-5">
            <div className={cn('rounded-full p-3', overBudget ? 'bg-red-100' : 'bg-emerald-100')}>
              {overBudget ? (
                <TrendingUp className="h-6 w-6 text-red-700" />
              ) : (
                <TrendingDown className="h-6 w-6 text-emerald-700" />
              )}
            </div>
            <div>
              <div className="text-sm text-muted-foreground">
                Variance ({overBudget ? 'over budget' : 'under budget'})
              </div>
              <div className={cn('text-2xl font-bold', overBudget ? 'text-red-700' : 'text-emerald-700')}>
                {formatCurrency(Math.abs(variance))}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Budget utilization progress */}
      <Card className="mb-6">
        <CardContent className="p-5">
          <div className="mb-2 flex items-center justify-between text-sm">
            <span className="font-medium">Budget Utilization</span>
            <span className="text-muted-foreground">{utilization.toFixed(0)}% of estimate spent</span>
          </div>
          <div className="h-3 w-full overflow-hidden rounded-full bg-secondary">
            <div
              className={cn('h-full rounded-full transition-all', overBudget ? 'bg-red-500' : 'bg-emerald-500')}
              style={{ width: `${utilization}%` }}
            />
          </div>
        </CardContent>
      </Card>

      {/* Chart */}
      {chartData.length > 0 && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="text-base">Estimated vs Actual by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-72 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="category" fontSize={12} />
                  <YAxis fontSize={12} tickFormatter={(v) => `${Number(v) / 1000}k`} />
                  <Tooltip formatter={(v) => formatCurrency(Number(v))} />
                  <Legend />
                  <Bar dataKey="Estimated" fill="hsl(200 80% 55%)" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="Actual" fill="hsl(150 60% 45%)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Editable table grouped by category */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-secondary text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 text-left">Item</th>
                  <th className="px-4 py-3 text-left">Vendor</th>
                  <th className="px-4 py-3 text-right">Estimated</th>
                  <th className="px-4 py-3 text-right">Actual</th>
                  <th className="px-4 py-3 text-left">Payment</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {isLoading && (
                  <tr>
                    <td colSpan={6} className="px-4 py-6 text-center text-muted-foreground">
                      Loading…
                    </td>
                  </tr>
                )}
                {grouped.map(([category, rows]) => {
                  const catEst = rows.reduce((s, r) => s + Number(r.estimated_cost), 0);
                  const catAct = rows.reduce((s, r) => s + Number(r.actual_cost ?? 0), 0);
                  return (
                    <CategoryGroup
                      key={category}
                      category={category}
                      rows={rows}
                      catEst={catEst}
                      catAct={catAct}
                      onStatusChange={(id, status) =>
                        updateCost.mutate({ id, payload: { paymentStatus: status } })
                      }
                      onDelete={(id) => deleteCost.mutate(id)}
                    />
                  );
                })}

                {/* Add row */}
                <tr className="border-t-2 bg-secondary/30">
                  <td className="px-4 py-2">
                    <div className="flex gap-2">
                      <Input
                        placeholder="Category"
                        value={newRow.category}
                        onChange={(e) => setNewRow((s) => ({ ...s, category: e.target.value }))}
                        className="h-8 w-32"
                      />
                      <Input
                        placeholder="Item name"
                        value={newRow.itemName}
                        onChange={(e) => setNewRow((s) => ({ ...s, itemName: e.target.value }))}
                        className="h-8"
                      />
                    </div>
                  </td>
                  <td className="px-4 py-2">
                    <Input
                      placeholder="Vendor"
                      value={newRow.vendor}
                      onChange={(e) => setNewRow((s) => ({ ...s, vendor: e.target.value }))}
                      className="h-8"
                    />
                  </td>
                  <td className="px-4 py-2 text-right">
                    <Input
                      type="number"
                      placeholder="0"
                      value={newRow.estimatedCost}
                      onChange={(e) => setNewRow((s) => ({ ...s, estimatedCost: e.target.value }))}
                      className="h-8 w-28 text-right"
                    />
                  </td>
                  <td className="px-4 py-2 text-center text-muted-foreground">—</td>
                  <td className="px-4 py-2 text-muted-foreground">—</td>
                  <td className="px-4 py-2">
                    <Button
                      size="sm"
                      className="h-8"
                      onClick={handleAdd}
                      disabled={!newRow.category.trim() || !newRow.itemName.trim() || createCost.isPending}
                    >
                      <Plus className="h-4 w-4" /> Add
                    </Button>
                  </td>
                </tr>
              </tbody>
              <tfoot className="bg-secondary font-semibold">
                <tr>
                  <td className="px-4 py-3" colSpan={2}>
                    Grand Total
                  </td>
                  <td className="px-4 py-3 text-right">{formatCurrency(grandEstimated)}</td>
                  <td className="px-4 py-3 text-right">{formatCurrency(grandActual)}</td>
                  <td className="px-4 py-3" colSpan={2}>
                    <span className={overBudget ? 'text-red-700' : 'text-emerald-700'}>
                      {overBudget ? 'Over' : 'Under'} by {formatCurrency(Math.abs(variance))}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function CategoryGroup({
  category,
  rows,
  catEst,
  catAct,
  onStatusChange,
  onDelete,
}: {
  category: string;
  rows: CostItem[];
  catEst: number;
  catAct: number;
  onStatusChange: (id: string, status: PaymentStatus) => void;
  onDelete: (id: string) => void;
}) {
  return (
    <>
      <tr className="bg-primary/5">
        <td colSpan={6} className="px-4 py-2 text-xs font-bold uppercase tracking-wide text-primary">
          {category} · {formatCurrency(catEst)} est / {formatCurrency(catAct)} actual
        </td>
      </tr>
      {rows.map((item) => (
        <tr key={item.id} className="border-b last:border-0 hover:bg-secondary/40">
          <td className="px-4 py-1.5 font-medium">{item.item_name}</td>
          <td className="px-4 py-1.5 text-muted-foreground">{item.vendor ?? '—'}</td>
          <td className="px-4 py-1.5 text-right">
            <EditableCostCell item={item} field="estimated_cost" />
          </td>
          <td className="px-4 py-1.5 text-right">
            <EditableCostCell item={item} field="actual_cost" />
          </td>
          <td className="px-4 py-1.5">
            <Select
              options={PAYMENT_OPTIONS}
              value={item.payment_status}
              onChange={(e) => onStatusChange(item.id, e.target.value as PaymentStatus)}
              className="h-8 w-28 border-transparent bg-transparent hover:border-input"
            />
          </td>
          <td className="px-4 py-1.5">
            <div className="flex items-center gap-1">
              <Badge variant={PAYMENT_VARIANT[item.payment_status]}>{item.payment_status}</Badge>
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 text-destructive"
                onClick={() => onDelete(item.id)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          </td>
        </tr>
      ))}
    </>
  );
}
