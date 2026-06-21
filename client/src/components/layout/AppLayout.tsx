import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { CalendarHeart, Users, Heart, LogOut } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuth } from '@/context/AuthContext';

export function AppLayout() {
  const { user, logout, hasRole } = useAuth();
  const navigate = useNavigate();

  const navItems = [
    { to: '/events', label: 'My Events', icon: CalendarHeart, show: true },
    { to: '/admin/users', label: 'User Admin', icon: Users, show: hasRole('SUPERADMIN', 'ADMIN') },
  ].filter((i) => i.show);

  const onLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="flex min-h-screen bg-background">
      <aside className="no-print sticky top-0 hidden h-screen w-60 shrink-0 flex-col border-r bg-card md:flex">
        <div className="flex items-center gap-2 px-6 py-5">
          <Heart className="h-6 w-6 fill-primary text-primary" />
          <span className="text-lg font-bold tracking-tight">Wedding Manager</span>
        </div>
        <nav className="flex flex-1 flex-col gap-1 px-3">
          {navItems.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
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
        <div className="border-t p-3">
          <div className="px-2 py-1 text-sm">
            <div className="truncate font-medium">{user?.email}</div>
            <div className="text-xs text-muted-foreground">{user?.role}</div>
          </div>
          <button
            onClick={onLogout}
            className="mt-1 flex w-full items-center gap-2 rounded-md px-2 py-2 text-sm text-muted-foreground hover:bg-secondary hover:text-foreground"
          >
            <LogOut className="h-4 w-4" /> Sign out
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-x-hidden">
        {/* Mobile top bar */}
        <div className="no-print flex items-center justify-between border-b bg-card px-3 py-2 md:hidden">
          <div className="flex items-center gap-2">
            <Heart className="h-5 w-5 fill-primary text-primary" />
            <span className="font-bold">Wedding Manager</span>
          </div>
          <button onClick={onLogout} className="text-sm text-muted-foreground">
            <LogOut className="h-4 w-4" />
          </button>
        </div>
        <div className="mx-auto max-w-7xl p-4 md:p-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
