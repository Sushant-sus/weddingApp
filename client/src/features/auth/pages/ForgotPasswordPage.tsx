import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AuthCard } from '../components/AuthCard';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { authApi } from '../auth.api';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async () => {
    setSubmitting(true);
    try {
      const res = await authApi.forgotPassword(email);
      toast(res.message, 'success');
      navigate(`/reset-password?email=${encodeURIComponent(email)}`);
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Request failed', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthCard
      title="Forgot password"
      subtitle="We'll email you a reset code"
      footer={<Link to="/login" className="text-primary hover:underline">Back to sign in</Link>}
    >
      <div className="space-y-3">
        <div>
          <Label>Email</Label>
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <Button className="w-full" onClick={onSubmit} disabled={submitting || !email}>
          {submitting ? 'Sending…' : 'Send Reset Code'}
        </Button>
      </div>
    </AuthCard>
  );
}
