import { Link } from 'react-router-dom';
import { ShieldX } from 'lucide-react';
import { Button } from '@/components/ui/button';

export function ForbiddenPage() {
  return (
    <div className="flex h-[60vh] flex-col items-center justify-center gap-3 text-center">
      <ShieldX className="h-10 w-10 text-destructive" />
      <h1 className="text-xl font-bold">Access denied</h1>
      <p className="text-sm text-muted-foreground">You don't have permission to view this page.</p>
      <Button asChild>
        <Link to="/events">Back to my events</Link>
      </Button>
    </div>
  );
}
