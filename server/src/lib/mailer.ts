import nodemailer, { type Transporter } from 'nodemailer';
import { env } from '../config/env.js';

let transporter: Transporter | null = null;

function getTransporter(): Transporter | null {
  if (!env.smtp.enabled) return null;
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.smtp.host,
      port: env.smtp.port,
      secure: env.smtp.port === 465,
      auth: { user: env.smtp.user, pass: env.smtp.pass },
    });
  }
  return transporter;
}

interface MailInput {
  to: string;
  subject: string;
  html: string;
  // Plain-text summary printed to console when SMTP is not configured.
  consoleSummary: string;
}

async function sendMail({ to, subject, html, consoleSummary }: MailInput) {
  const t = getTransporter();
  if (!t) {
    // Dev fallback: no SMTP configured → log so the flow stays testable.
    console.log('\n──────── EMAIL (SMTP not configured) ────────');
    console.log(`To:      ${to}`);
    console.log(`Subject: ${subject}`);
    console.log(consoleSummary);
    console.log('─────────────────────────────────────────────\n');
    return;
  }
  await t.sendMail({ from: env.smtp.from, to, subject, html });
}

const shell = (heading: string, body: string) => `
  <div style="font-family:system-ui,Segoe UI,Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #f0d9e0;border-radius:12px">
    <h2 style="color:#be123c;margin-top:0">💍 ${heading}</h2>
    ${body}
    <p style="color:#9ca3af;font-size:12px;margin-top:24px">Wedding Management System</p>
  </div>`;

const otpBlock = (otp: string) => `
  <div style="font-size:32px;font-weight:700;letter-spacing:8px;background:#fdf2f8;color:#be123c;
              text-align:center;padding:16px;border-radius:8px;margin:16px 0">${otp}</div>
  <p style="color:#6b7280">This code is valid for <strong>10 minutes</strong>. If you didn't request this, ignore this email.</p>`;

export async function sendVerifyEmailOtp(to: string, otp: string) {
  await sendMail({
    to,
    subject: 'Verify your email — Wedding App',
    html: shell('Verify your email', `<p>Use the code below to verify your email address:</p>${otpBlock(otp)}`),
    consoleSummary: `VERIFY_EMAIL OTP: ${otp}`,
  });
}

export async function sendResetPasswordOtp(to: string, otp: string) {
  await sendMail({
    to,
    subject: 'Reset your password — Wedding App',
    html: shell('Reset your password', `<p>Use the code below to reset your password:</p>${otpBlock(otp)}`),
    consoleSummary: `RESET_PASSWORD OTP: ${otp}`,
  });
}

interface InviteInput {
  to: string;
  eventName: string;
  eventDate: string;
  inviterName: string;
  role: string;
  roleDescription: string;
  token: string;
}

export async function sendEventInvite(input: InviteInput) {
  const acceptUrl = `${env.appUrl}/invite/accept?token=${input.token}`;
  const declineUrl = `${env.appUrl}/invite/decline?token=${input.token}`;
  const html = shell(
    `Invitation to ${input.eventName}`,
    `
    <p><strong>${input.inviterName}</strong> invited you to collaborate on
       <strong>${input.eventName}</strong> (${input.eventDate}).</p>
    <p>Your role will be <strong>${input.role}</strong> — ${input.roleDescription}</p>
    <div style="margin:20px 0">
      <a href="${acceptUrl}" style="background:#be123c;color:#fff;text-decoration:none;
         padding:10px 18px;border-radius:8px;margin-right:8px">Accept Invite</a>
      <a href="${declineUrl}" style="background:#f3f4f6;color:#374151;text-decoration:none;
         padding:10px 18px;border-radius:8px">Decline</a>
    </div>
    <p style="color:#6b7280">This invite expires in <strong>48 hours</strong>.</p>`,
  );
  await sendMail({
    to: input.to,
    subject: `You've been invited to collaborate on ${input.eventName}`,
    html,
    consoleSummary: `EVENT INVITE → role=${input.role} token=${input.token}\nAccept: ${acceptUrl}`,
  });
}
