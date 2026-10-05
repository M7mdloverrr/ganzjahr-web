import { createHash, randomBytes, scrypt, timingSafeEqual } from "node:crypto";

type Cmd = (string | number)[];

const url = process.env.KV_REST_API_URL ?? process.env.UPSTASH_REDIS_REST_URL;
const token = process.env.KV_REST_API_TOKEN ?? process.env.UPSTASH_REDIS_REST_TOKEN;

export const storageReady = Boolean(url && token);

export const KEYS = {
  data: "gj:data",
  rev: "gj:rev",
  password: "gj:password",
  token: (t: string) => `gj:token:${createHash("sha256").update(t).digest("hex")}`,
  fails: (ip: string) => `gj:fails:${ip}`,
};

export async function redis<T = unknown>(...cmds: Cmd[]): Promise<T[]> {
  if (!storageReady) throw new Error("storage");
  const res = await fetch(`${url}/pipeline`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(cmds),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`redis ${res.status}`);
  const out = (await res.json()) as { result?: T; error?: string }[];
  return out.map((r) => {
    if (r.error) throw new Error(r.error);
    return r.result as T;
  });
}

const scryptAsync = (pw: string, salt: Buffer) =>
  new Promise<Buffer>((resolve, reject) => scrypt(pw, salt, 32, (e, key) => (e ? reject(e) : resolve(key))));

export async function hashPassword(pw: string) {
  const salt = randomBytes(16);
  return `${salt.toString("hex")}:${(await scryptAsync(pw, salt)).toString("hex")}`;
}

export async function checkPassword(pw: string, stored: string) {
  const [salt, hash] = stored.split(":");
  const key = await scryptAsync(pw, Buffer.from(salt, "hex"));
  return timingSafeEqual(key, Buffer.from(hash, "hex"));
}

export const newToken = () => randomBytes(32).toString("base64url");

export const json = (body: unknown, status = 200) =>
  Response.json(body, { status, headers: { "Cache-Control": "no-store" } });

export function bearer(req: Request) {
  const h = req.headers.get("authorization") ?? "";
  return h.startsWith("Bearer ") ? h.slice(7) : null;
}

export async function authorized(req: Request) {
  const t = bearer(req);
  if (!t) return false;
  const [ok] = await redis<number>(["EXISTS", KEYS.token(t)]);
  return ok === 1;
}
