import { AuthForm } from "@/components/auth-form";
import { isSignupEnabled } from "@/lib/security-config";

export const metadata = { title: "Sign in · Luqa" };

export default function LoginPage() {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1.5">
        <h1 className="text-2xl font-semibold tracking-tight">Welcome back</h1>
        <p className="text-sm text-muted">Sign in to track your day.</p>
      </div>
      <AuthForm mode="login" signupEnabled={isSignupEnabled()} />
    </div>
  );
}
