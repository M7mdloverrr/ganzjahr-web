import { KEYS, bearer, checkPassword, hashPassword, json, newToken, redis, storageReady } from "@/lib/cloud";

const TOKEN_TTL = 60 * 60 * 24 * 365 * 5;

export async function GET() {
  if (!storageReady) return json({ storage: false, account: false });
  const [account] = await redis<number>(["EXISTS", KEYS.password]);
  return json({ storage: true, account: account === 1 });
}

export async function POST(req: Request) {
  if (!storageReady) return json({ error: "storage" }, 503);
  const { user: rawUser, password, create } = (await req.json().catch(() => ({}))) as {
    user?: string;
    password?: string;
    create?: boolean;
  };
  const user = typeof rawUser === "string" ? rawUser.trim().toLowerCase() : "";
  if (!user) return json({ error: "user" }, 400);
  if (typeof password !== "string" || password.length < 6) return json({ error: "short" }, 400);

  const ip = (req.headers.get("x-forwarded-for") ?? "local").split(",")[0].trim();
  const [fails] = await redis<string | null>(["GET", KEYS.fails(ip)]);
  if (Number(fails ?? 0) >= 10) return json({ error: "locked" }, 429);

  if (create) {
    const [set] = await redis<string | null>(["SET", KEYS.password, await hashPassword(password), "NX"]);
    if (set !== "OK") return json({ error: "exists" }, 409);
    await redis(["SET", KEYS.user, user]);
  } else {
    const [stored, storedUser] = await redis<string | null>(["GET", KEYS.password], ["GET", KEYS.user]);
    if (!stored) return json({ error: "noaccount" }, 404);
    const passwordOk = await checkPassword(password, stored);
    if (!passwordOk || storedUser !== user) {
      await redis(["INCR", KEYS.fails(ip)], ["EXPIRE", KEYS.fails(ip), 900]);
      return json({ error: "wrong" }, 401);
    }
  }
  const token = newToken();
  await redis(["SET", KEYS.token(token), "1", "EX", TOKEN_TTL]);
  return json({ token });
}

export async function DELETE(req: Request) {
  const t = bearer(req);
  if (t && storageReady) await redis(["DEL", KEYS.token(t)]);
  return json({ ok: true });
}
