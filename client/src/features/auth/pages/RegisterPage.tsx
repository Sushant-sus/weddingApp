import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { AuthCard } from '../components/AuthCard';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { authApi } from '../auth.api';
import { toast } from '@/components/ui/toast';
import { ApiError } from '@/lib/api';

const schema = z
  .object({
    fullName: z.string().min(2, 'Enter your full name').max(100),
    email: z.string().email(),
    password: z
      .string()
      .min(8, 'At least 8 characters')
      .regex(/[A-Z]/, 'One uppercase letter')
      .regex(/[0-9]/, 'One number')
      .regex(/[^a-zA-Z0-9]/, 'One special character'),
    confirmPassword: z.string(),
  })
  .refine((d) => d.password === d.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });
type Form = z.infer<typeof schema>;

export function RegisterPage() {
  const navigate = useNavigate();
  const [submitting, setSubmitting] = useState(false);
  const { register, handleSubmit, formState: { errors } } = useForm<Form>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: Form) => {
    setSubmitting(true);
    try {
      await authApi.register(data);
      toast('Account created! Check your email for the OTP.', 'success');
      navigate(`/verify-email?email=${encodeURIComponent(data.email)}`);
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Registration failed', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthCard
      title="Create your account"
      subtitle="Start planning your wedding"
      footer={<>Already have an account? <Link to="/login" className="text-primary hover:underline">Sign in</Link></>}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-3">
        <div>
          <Label>Full Name</Label>
          <Input {...register('fullName')} />
          {errors.fullName && <p className="mt-1 text-xs text-destructive">{errors.fullName.message}</p>}
        </div>
        <div>
          <Label>Email</Label>
          <Input type="email" {...register('email')} />
          {errors.email && <p className="mt-1 text-xs text-destructive">{errors.email.message}</p>}
        </div>
        <div>
          <Label>Password</Label>
          <Input type="password" {...register('password')} />
          {errors.password && <p className="mt-1 text-xs text-destructive">{errors.password.message}</p>}
        </div>
        <div>
          <Label>Confirm Password</Label>
          <Input type="password" {...register('confirmPassword')} />
          {errors.confirmPassword && (
            <p className="mt-1 text-xs text-destructive">{errors.confirmPassword.message}</p>
          )}
        </div>
        <Button type="submit" className="w-full" disabled={submitting}>
          {submitting ? 'Creating…' : 'Create Account'}
        </Button>
      </form>
    </AuthCard>
  );
}
