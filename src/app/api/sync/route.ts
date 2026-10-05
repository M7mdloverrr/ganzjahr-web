import { KEYS, authorized, json, redis, storageReady } from "@/lib/cloud";

const KEY = /^(meta|customers|catalog|documents)\/[\w-]{1,100}$/;

export async function GET(req: Request) {
  if (!storageReady) return json({ error: "storage" }, 503);
  if (!(await authorized(req))) return json({ error: "auth" }, 401);
  const since = new URL(req.url).searchParams.get("since");
  const [rev] = await redis<string | null>(["GET", KEYS.rev]);
  const current = Number(rev ?? 0);
  if (since !== null && Number(since) === current) return json({ rev: current });
  const [flat] = await redis<string[]>(["HGETALL", KEYS.data]);
  const items: Record<string, string> = {};
  for (let i = 0; i + 1 < flat.length; i += 2) items[flat[i]] = flat[i + 1];
  return json({ rev: current, items });
}

export async function POST(req: Request) {
  if (!storageReady) return json({ error: "storage" }, 503);
  if (!(await authorized(req))) return json({ error: "auth" }, 401);
  const body = (await req.json().catch(() => null)) as { set?: Record<string, unknown>; del?: unknown[] } | null;
  const set = Object.entries(body?.set ?? {});
  const del = body?.del ?? [];
  if (!set.every(([k, v]) => KEY.test(k) && typeof v === "string") || !del.every((k) => typeof k === "string" && KEY.test(k))) {
    return json({ error: "bad" }, 400);
  }
  const cmds: (string | number)[][] = [];
  if (set.length) cmds.push(["HSET", KEYS.data, ...set.flatMap(([k, v]) => [k, v as string])]);
  if (del.length) cmds.push(["HDEL", KEYS.data, ...(del as string[])]);
  cmds.push(["INCR", KEYS.rev]);
  const out = await redis<number>(...cmds);
  return json({ rev: out[out.length - 1] });
}
