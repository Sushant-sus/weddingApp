import { NavLink, Outlet } from 'react-router-dom';
import { LayoutDashboard, Users, Gift, CalendarClock, Wallet, Heart } from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/guests', label: 'Guests', icon: Users },
  { to: '/gifts', label: 'Gifts', icon: Gift },
  { to: '/itinerary', label: 'Itinerary', icon: CalendarClock },
  { to: '/costs', label: 'Cost Tracker', icon: Wallet },
];

export function AppLayout() {
  return (
    <div className="flex min-h-screen bg-background">
      <aside className="no-print sticky top-0 hidden h-screen w-60 shrink-0 flex-col border-r bg-card md:flex">
        <div className="flex items-center gap-2 px-6 py-5">
          <Heart className="h-6 w-6 fill-primary text-primary" />
          <span className="text-lg font-bold tracking-tight">Wedding Manager</span>
        </div>
        <nav className="flex flex-1 flex-col gap-1 px-3">
          {navItems.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:bg-secondary hover:text-foreground',
                )
              }
            >
              <Icon className="h-4 w-4" />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="px-6 py-4 text-xs text-muted-foreground">v1.0 · Built with ♥</div>
      </aside>

      <main className="flex-1 overflow-x-hidden">
        {/* Mobile top nav */}
        <div className="no-print flex items-center gap-1 overflow-x-auto border-b bg-card px-2 py-2 md:hidden">
          {navItems.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                cn(
                  'flex shrink-0 items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium',
                  isActive ? 'bg-primary text-primary-foreground' : 'text-muted-foreground',
                )
              }
            >
              <Icon className="h-3.5 w-3.5" />
              {label}
            </NavLink>
          ))}
        </div>
        <div className="mx-auto max-w-7xl p-4 md:p-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
