import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { AuthCard } from '../components/AuthCard';
import { OtpInput } from '../components/OtpInput';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { authApi } from '../auth.api';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

export function VerifyEmailPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [email, setEmail] = useState(params.get('email') ?? '');
  const [otp, setOtp] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async () => {
    if (otp.length !== 6) return toast('Enter the 6-digit code', 'error');
    setSubmitting(true);
    try {
      await authApi.verifyEmail(email, otp);
      toast('Email verified! You can now sign in.', 'success');
      navigate('/login');
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Verification failed', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthCard
      title="Verify your email"
      subtitle="Enter the 6-digit code we sent you"
      footer={<Link to="/login" className="text-primary hover:underline">Back to sign in</Link>}
    >
      <div className="space-y-4">
        <div>
          <Label>Email</Label>
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div>
          <Label>Verification Code</Label>
          <div className="mt-2">
            <OtpInput value={otp} onChange={setOtp} />
          </div>
        </div>
        <Button className="w-full" onClick={onSubmit} disabled={submitting}>
          {submitting ? 'Verifying…' : 'Verify Email'}
        </Button>
      </div>
    </AuthCard>
  );
}
