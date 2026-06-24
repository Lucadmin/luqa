import { AuthForm } from "@/components/auth-form";
import Link from "next/link";
import {
  isSignupEnabled,
  signupRequiresToken,
} from "@/lib/security-config";

export const metadata = { title: "Sign up · Luqa" };

export default function SignupPage() {
  if (!isSignupEnabled()) {
    return (
      <div className="flex flex-col gap-6">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-2xl font-semibold tracking-tight">
            Account creation is closed
          </h1>
          <p className="text-sm text-muted">
            This Luqa instance only accepts the configured owner account.
          </p>
        </div>
        <Link href="/login" className="text-sm font-medium text-primary hover:underline">
          Back to sign in
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1.5">
        <h1 className="text-2xl font-semibold tracking-tight">
          Create your account
        </h1>
        <p className="text-sm text-muted">Start tracking in five-minute blocks.</p>
      </div>
      <AuthForm mode="signup" signupRequiresToken={signupRequiresToken()} />
    </div>
  );
}
