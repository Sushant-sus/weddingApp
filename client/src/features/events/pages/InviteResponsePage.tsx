import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { Heart } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { eventApi } from '../event.api';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

// Handles /invite/accept?token=… and /invite/decline?token=… from invite emails.
export function InviteResponsePage() {
  const { action } = useParams<{ action: 'accept' | 'decline' }>();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const token = params.get('token') ?? '';
  const [status, setStatus] = useState<'working' | 'done' | 'error'>('working');
  const [message, setMessage] = useState('Processing your invitation…');
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current) return;
    ran.current = true;
    (async () => {
      if (!token) {
        setStatus('error');
        setMessage('Missing invite token.');
        return;
      }
      try {
        if (action === 'decline') {
          await eventApi.declineInvite(token);
          setMessage('Invitation declined.');
        } else {
          await eventApi.acceptInvite(token);
          setMessage('Invitation accepted! Redirecting…');
          setTimeout(() => navigate('/events'), 1200);
        }
        setStatus('done');
      } catch (e) {
        setStatus('error');
        setMessage(e instanceof ApiError ? e.message : 'Could not process invitation.');
      }
    })();
  }, [action, token, navigate]);

  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <div className="w-full max-w-sm rounded-xl border bg-card p-8 text-center shadow-sm">
        <Heart className="mx-auto h-9 w-9 fill-primary text-primary" />
        <p className="mt-4 text-sm text-muted-foreground">{message}</p>
        {status !== 'working' && (
          <Button className="mt-4" onClick={() => navigate('/events')}>
            Go to My Events
          </Button>
        )}
      </div>
    </div>
  );
}
