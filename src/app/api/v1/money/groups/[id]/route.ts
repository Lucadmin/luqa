import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { toGroupDTO } from "@/lib/serializers";
import {
  moneyRoute,
  notFound,
  readJson,
  rejected,
} from "@/lib/server/money-routes";
import { updateGroupSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/v1/money/groups/[id] — rename, restyle, change membership, archive.
export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id } = await params;
    const existing = await db.personGroup.findFirst({
      where: { id, userId: session.userId },
    });
    if (!existing) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updateGroupSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    if (d.name !== undefined && d.name !== existing.name) {
      const taken = await db.personGroup.findFirst({
        where: { userId: session.userId, name: d.name, id: { not: id } },
        select: { id: true },
      });
      if (taken) return rejected(`You already have a group called ${d.name}`);
    }

    let memberIds: string[] | null = null;
    if (d.memberIds !== undefined) {
      memberIds = [...new Set(d.memberIds)];
      if (memberIds.length > 0) {
        const owned = await db.person.count({
          where: { userId: session.userId, id: { in: memberIds } },
        });
        if (owned !== memberIds.length) return rejected("Unknown person");
      }
    }

    const group = await db.personGroup.update({
      where: { id },
      data: {
        ...(d.name !== undefined ? { name: d.name } : {}),
        ...(d.color !== undefined ? { color: d.color } : {}),
        ...(d.emoji !== undefined ? { emoji: d.emoji ?? null } : {}),
        ...(d.order !== undefined ? { order: d.order } : {}),
        ...(d.archived !== undefined
          ? { archivedAt: d.archived ? new Date() : null }
          : {}),
        // Membership is replaced wholesale — the editor always sends the full set.
        ...(memberIds
          ? {
              members: {
                deleteMany: {},
                create: memberIds.map((personId) => ({ personId })),
              },
            }
          : {}),
      },
      include: { members: true },
    });

    return mobileJson({ group: toGroupDTO(group) });
  },
);

// DELETE /api/v1/money/groups/[id] — remove a group. Past expenses keep their
// people and amounts; they simply lose the group label.
export const DELETE = moneyRoute<[Params]>(
  async (session, _request, { params }) => {
    const { id } = await params;
    await db.personGroup.deleteMany({ where: { id, userId: session.userId } });
    return new Response(null, { status: 204 });
  },
);
