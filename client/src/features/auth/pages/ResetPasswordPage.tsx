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

export function ResetPasswordPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [email, setEmail] = useState(params.get('email') ?? '');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async () => {
    if (otp.length !== 6) return toast('Enter the 6-digit code', 'error');
    setSubmitting(true);
    try {
      await authApi.resetPassword(email, otp, newPassword);
      toast('Password reset! Please sign in.', 'success');
      navigate('/login');
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Reset failed', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthCard
      title="Reset password"
      subtitle="Enter the code and your new password"
      footer={<Link to="/login" className="text-primary hover:underline">Back to sign in</Link>}
    >
      <div className="space-y-4">
        <div>
          <Label>Email</Label>
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div>
          <Label>Reset Code</Label>
          <div className="mt-2">
            <OtpInput value={otp} onChange={setOtp} />
          </div>
        </div>
        <div>
          <Label>New Password</Label>
          <Input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
          <p className="mt-1 text-xs text-muted-foreground">
            8+ chars with uppercase, number, and special character.
          </p>
        </div>
        <Button className="w-full" onClick={onSubmit} disabled={submitting}>
          {submitting ? 'Resetting…' : 'Reset Password'}
        </Button>
      </div>
    </AuthCard>
  );
}
