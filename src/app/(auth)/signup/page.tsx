import { AuthForm } from "@/components/auth-form";

export const metadata = { title: "Sign up · Luqa" };

export default function SignupPage() {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1.5">
        <h1 className="text-2xl font-semibold tracking-tight">
          Create your account
        </h1>
        <p className="text-sm text-muted">Start tracking in five-minute blocks.</p>
      </div>
      <AuthForm mode="signup" />
    </div>
  );
}
