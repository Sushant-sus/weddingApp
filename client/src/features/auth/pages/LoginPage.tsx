import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { AuthCard } from '../components/AuthCard';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useAuth } from '@/context/AuthContext';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

const schema = z.object({ email: z.string().email(), password: z.string().min(1, 'Required') });
type Form = z.infer<typeof schema>;

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [submitting, setSubmitting] = useState(false);
  const { register, handleSubmit, formState: { errors } } = useForm<Form>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: Form) => {
    setSubmitting(true);
    try {
      await login(data.email, data.password);
      const to = (location.state as { from?: { pathname: string } })?.from?.pathname ?? '/events';
      navigate(to, { replace: true });
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Login failed', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthCard
      title="Welcome back"
      subtitle="Sign in to your account"
      footer={
        <>
          <Link to="/forgot-password" className="text-primary hover:underline">Forgot password?</Link>
          <span className="mx-2">·</span>
          New here? <Link to="/register" className="text-primary hover:underline">Create account</Link>
        </>
      }
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-3">
        <div>
          <Label>Email</Label>
          <Input type="email" autoComplete="email" {...register('email')} />
          {errors.email && <p className="mt-1 text-xs text-destructive">{errors.email.message}</p>}
        </div>
        <div>
          <Label>Password</Label>
          <Input type="password" autoComplete="current-password" {...register('password')} />
          {errors.password && <p className="mt-1 text-xs text-destructive">{errors.password.message}</p>}
        </div>
        <Button type="submit" className="w-full" disabled={submitting}>
          {submitting ? 'Signing in…' : 'Sign In'}
        </Button>
      </form>
    </AuthCard>
  );
}
