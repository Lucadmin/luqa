import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toDateKey } from "@/lib/life";
import type { SettingsDTO } from "@/lib/types";
import { updateSettingsSchema } from "@/lib/validations";

const SELECT = {
  name: true,
  email: true,
  dayStartHour: true,
  dailyGoalMinutes: true,
  weekStartsOn: true,
  birthDate: true,
  lifeExpectancyYears: true,
} as const;

// The DB row carries birthDate as a Date; the wire type wants "YYYY-MM-DD".
function toSettingsDTO(user: {
  name: string | null;
  email: string;
  dayStartHour: number;
  dailyGoalMinutes: number;
  weekStartsOn: number;
  birthDate: Date | null;
  lifeExpectancyYears: number;
}): SettingsDTO {
  return {
    name: user.name,
    email: user.email,
    dayStartHour: user.dayStartHour,
    dailyGoalMinutes: user.dailyGoalMinutes,
    weekStartsOn: user.weekStartsOn,
    birthDate: user.birthDate ? toDateKey(user.birthDate) : null,
    lifeExpectancyYears: user.lifeExpectancyYears,
  };
}

// GET /api/settings — the current user's profile + preferences.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const user = await db.user.findUnique({ where: { id: userId }, select: SELECT });
  if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json({ settings: toSettingsDTO(user) });
}

// PATCH /api/settings — update profile + preferences.
export async function PATCH(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateSettingsSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const { name, birthDate, ...rest } = parsed.data;
  const user = await db.user.update({
    where: { id: userId },
    data: {
      ...(name !== undefined ? { name: name?.trim() || null } : {}),
      ...(birthDate !== undefined
        ? { birthDate: birthDate ? new Date(`${birthDate}T00:00:00.000Z`) : null }
        : {}),
      ...rest,
    },
    select: SELECT,
  });

  return NextResponse.json({ settings: toSettingsDTO(user) });
}
