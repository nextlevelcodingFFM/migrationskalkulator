// KI-Schätzhilfe für den Migrationskalkulator (GitHub-Pages-Version).
// Die Webseite schickt den Dialog hierher; die Funktion prüft den Zugang
// (angemeldete, freigeschaltete Person oder gültiger Zugangslink) und ruft
// die Claude-API von Anthropic auf. Der API-Schlüssel liegt nur als Secret
// in Supabase (ANTHROPIC_API_KEY), nie im Repository oder in der Webseite.
//
// Secrets:   ANTHROPIC_API_KEY  (Pflicht)
//            ANTHROPIC_MODEL    (optional, Standard: claude-sonnet-5-5)
//            KI_ORIGINS         (optional, erlaubte Herkunft, kommagetrennt)
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const ORIGINS = (Deno.env.get("KI_ORIGINS") ?? "https://nextlevelcodingffm.github.io")
  .split(",").map((s) => s.trim()).filter(Boolean);
const MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5-5";
const MAX_SYSTEM = 40000;   // Zeichen für Anweisungen und Kontext
const MAX_MSG = 20000;      // Zeichen je Nachricht
const MAX_TURNS = 30;       // nur die letzten Nachrichten
const MAX_TOKENS = 4000;    // Länge einer Antwort

type Turn = { role: "user" | "assistant"; content: string };

function corsHeaders(origin: string): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": ORIGINS.includes(origin) ? origin : ORIGINS[0],
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-zugang, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

Deno.serve(async (req: Request) => {
  const cors = corsHeaders(req.headers.get("origin") ?? "");
  const json = (status: number, body: unknown) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "methode" });

  // Zugang prüfen: dieselben Regeln wie für die Tabelle "kommunen"
  const zugang = req.headers.get("x-zugang") ?? "";
  const headers: Record<string, string> = { Authorization: req.headers.get("Authorization") ?? "" };
  if (zugang) headers["x-zugang"] = zugang;
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: erlaubt, error: authErr } = await sb.rpc(zugang ? "link_gueltig" : "ist_zugelassen");
  if (authErr || erlaubt !== true) return json(403, { error: "kein_zugang" });

  let body: { ping?: boolean; system?: unknown; messages?: unknown };
  try { body = await req.json(); } catch { return json(400, { error: "ungueltig" }); }

  const key = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
  if (body?.ping) return json(200, { ok: true, bereit: key.length > 0 });
  if (!key) return json(503, { error: "nicht_eingerichtet" });

  // Nachrichten prüfen und aufeinanderfolgende gleiche Rollen zusammenführen
  const raw = Array.isArray(body.messages) ? body.messages : [];
  const turns: Turn[] = [];
  for (const m of raw.slice(-MAX_TURNS)) {
    if (!m || (m.role !== "user" && m.role !== "assistant") || typeof m.content !== "string") continue;
    const content = m.content.slice(0, MAX_MSG).trim();
    if (!content) continue;
    const last = turns[turns.length - 1];
    if (last && last.role === m.role) last.content += "\n\n" + content;
    else turns.push({ role: m.role, content });
  }
  while (turns.length && turns[0].role !== "user") turns.shift();
  if (!turns.length || turns[turns.length - 1].role !== "user") return json(400, { error: "ungueltig" });
  const system = String(body.system ?? "").slice(0, MAX_SYSTEM);

  let res: Response;
  try {
    res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({ model: MODEL, max_tokens: MAX_TOKENS, system, messages: turns }),
    });
  } catch {
    return json(502, { error: "upstream_error" });
  }
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const typ = data?.error?.type ?? "";
    const msg = String(data?.error?.message ?? "");
    const code =
      res.status === 401 || res.status === 403 ? "schluessel_ungueltig" :
      res.status === 429 || typ === "rate_limit_error" ? "rate_limited" :
      res.status === 529 || typ === "overloaded_error" ? "ueberlastet" :
      /credit|balance|billing/i.test(msg) ? "kein_guthaben" : "upstream_error";
    console.error("Anthropic-Fehler", res.status, typ, msg.slice(0, 200));
    return json(502, { error: code });
  }
  const text = (data?.content ?? [])
    .filter((c: { type: string }) => c.type === "text")
    .map((c: { text: string }) => c.text).join("");
  return json(200, { text, truncated: data?.stop_reason === "max_tokens" });
});
