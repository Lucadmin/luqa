import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { hashPassword } from "@/lib/password";
import { isAllowedEmail, normalizeEmail } from "@/lib/security-config";
import { verifySignupToken } from "@/lib/signup-security";
import { signupSchema } from "@/lib/validations";

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = signupSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const { email, inviteToken, password, name } = parsed.data;
  const normalizedEmail = normalizeEmail(email);

  if (!isAllowedEmail(normalizedEmail) || !verifySignupToken(inviteToken)) {
    return NextResponse.json(
      { error: "Account creation is restricted" },
      { status: 403 },
    );
  }

  const existing = await db.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (existing) {
    return NextResponse.json(
      { error: "An account with this email already exists" },
      { status: 409 },
    );
  }

  const passwordHash = await hashPassword(password);
  const user = await db.user.create({
    data: { email: normalizedEmail, passwordHash, name },
    select: { id: true, email: true, name: true },
  });

  return NextResponse.json({ user }, { status: 201 });
}
