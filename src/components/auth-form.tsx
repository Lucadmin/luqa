"use client";

import { signIn } from "next-auth/react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

type Mode = "login" | "signup";

export function AuthForm({
  mode,
  signupEnabled = false,
  signupRequiresToken = false,
}: {
  mode: Mode;
  signupEnabled?: boolean;
  signupRequiresToken?: boolean;
}) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setPending(true);

    const form = new FormData(e.currentTarget);
    const email = String(form.get("email") ?? "");
    const password = String(form.get("password") ?? "");
    const name = String(form.get("name") ?? "");
    const inviteToken = String(form.get("inviteToken") ?? "");

    try {
      if (mode === "signup") {
        const res = await fetch("/api/signup", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email,
            inviteToken: inviteToken || undefined,
            password,
            name: name || undefined,
          }),
        });
        if (!res.ok) {
          const data = await res.json().catch(() => ({}));
          setError(data.error ?? "Could not create account");
          setPending(false);
          return;
        }
      }

      const result = await signIn("credentials", {
        email,
        password,
        redirect: false,
      });

      if (result?.error) {
        setError("Invalid email or password");
        setPending(false);
        return;
      }

      router.push("/");
      router.refresh();
    } catch {
      setError("Something went wrong. Please try again.");
      setPending(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-3">
      {mode === "signup" && (
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">Name</span>
          <Input name="name" type="text" placeholder="Your name" autoComplete="name" />
        </label>
      )}

      {mode === "signup" && signupRequiresToken && (
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">Invite code</span>
          <Input
            name="inviteToken"
            type="password"
            required
            placeholder="Required"
            autoComplete="off"
          />
        </label>
      )}

      <label className="flex flex-col gap-1.5">
        <span className="text-xs font-medium text-muted">Email</span>
        <Input
          name="email"
          type="email"
          required
          placeholder="you@example.com"
          autoComplete="email"
        />
      </label>

      <label className="flex flex-col gap-1.5">
        <span className="text-xs font-medium text-muted">Password</span>
        <Input
          name="password"
          type="password"
          required
          minLength={8}
          placeholder="••••••••"
          autoComplete={mode === "login" ? "current-password" : "new-password"}
        />
      </label>

      {error && (
        <p className="text-sm text-red-500" role="alert">
          {error}
        </p>
      )}

      <Button type="submit" size="lg" disabled={pending} className="mt-2 w-full">
        {pending
          ? "Please wait…"
          : mode === "login"
            ? "Sign in"
            : "Create account"}
      </Button>

      <p className="mt-2 text-center text-sm text-muted">
        {mode === "login" ? (
          signupEnabled ? (
            <>
              No account?{" "}
              <Link href="/signup" className="font-medium text-primary hover:underline">
                Sign up
              </Link>
            </>
          ) : (
            "Account creation is closed."
          )
        ) : (
          <>
            Already have an account?{" "}
            <Link href="/login" className="font-medium text-primary hover:underline">
              Sign in
            </Link>
          </>
        )}
      </p>
    </form>
  );
}
