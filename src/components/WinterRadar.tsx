"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Snowflake, Thermometer, Radio, TriangleAlert, CheckCircle2 } from "lucide-react";
import Section from "@/components/Section";
import { site } from "@/lib/site";

type Day = {
  date: string;
  min: number;
  max: number;
  snow: number;
  rain: number;
};

type Status = "ruhe" | "beobachtung" | "einsatz";

const STATUS: Record<
  Status,
  { label: string; text: string; dot: string; glow: string; icon: typeof Snowflake }
> = {
  ruhe: {
    label: "Ruhemodus",
    text: "Kein Frost-, Schnee- oder Glättereignis in den nächsten 7 Tagen. Teams sind in der Grünpflege.",
    dot: "bg-leaf-500",
    glow: "shadow-leaf-500/40",
    icon: CheckCircle2,
  },
  beobachtung: {
    label: "Beobachtung",
    text: "Frost möglich. Streugut ist geladen, Bereitschaft wird auf Abruf hochgefahren.",
    dot: "bg-amber-400",
    glow: "shadow-amber-400/40",
    icon: TriangleAlert,
  },
  einsatz: {
    label: "Einsatzbereitschaft",
    text: "Schnee oder Glätte in Sicht. Räumfahrzeuge sind disponiert, erste Tour startet um 04:00 Uhr.",
    dot: "bg-frost-400",
    glow: "shadow-frost-400/50",
    icon: Snowflake,
  },
};

function statusFor(days: Day[]): Status {
  if (!days.length) return "ruhe";
  const next3 = days.slice(0, 3);
  if (next3.some((d) => d.snow > 0.2 || (d.min <= 0 && d.rain > 0.5))) return "einsatz";
  if (days.some((d) => d.min <= 1)) return "beobachtung";
  return "ruhe";
}

export default function WinterRadar() {
  const [days, setDays] = useState<Day[]>([]);
  const [state, setState] = useState<"loading" | "ok" | "error">("loading");

  useEffect(() => {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${site.lat}&longitude=${site.lon}&daily=temperature_2m_min,temperature_2m_max,snowfall_sum,precipitation_sum&timezone=Europe%2FBerlin&forecast_days=7`;
    fetch(url)
      .then((r) => r.json())
      .then((j) => {
        const d = j?.daily;
        if (!d?.time) throw new Error("no data");
        setDays(
          d.time.map((t: string, i: number) => ({
            date: t,
            min: d.temperature_2m_min[i],
            max: d.temperature_2m_max[i],
            snow: d.snowfall_sum[i] ?? 0,
            rain: d.precipitation_sum[i] ?? 0,
          })),
        );
        setState("ok");
      })
      .catch(() => setState("error"));
  }, []);

  const status = statusFor(days);
  const S = STATUS[status];
  const Icon = S.icon;

  return (
    <Section
      id="winterradar"
      eyebrow="Winter-Radar · live"
      title="Wir sehen den Schnee, bevor du ihn siehst."
      subtitle={`Diese Ampel zieht sich in Echtzeit die 7-Tage-Prognose für ${site.city} und zeigt dir, in welchem Einsatzmodus unsere Teams gerade sind. Kein Marketing – echte Wetterdaten.`}
    >
      <div className="grid gap-6 lg:grid-cols-[minmax(0,380px)_minmax(0,1fr)]">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="glass relative overflow-hidden rounded-3xl p-7"
        >
          <div className="flex items-center gap-2 text-[11px] font-bold uppercase tracking-[0.2em] text-white/45">
            <Radio className="size-3.5 text-leaf-400" />
            Status {site.city}
          </div>
          <div className="mt-6 flex items-center gap-4">
            <span className="relative grid size-16 place-items-center">
              <span
                className={`absolute inset-0 animate-ping rounded-full ${S.dot} opacity-20`}
              />
              <span
                className={`grid size-16 place-items-center rounded-full ${S.dot} shadow-2xl ${S.glow}`}
              >
                <Icon className="size-7 text-ink-950" />
              </span>
            </span>
            <div>
              <p className="text-2xl font-extrabold tracking-tight">
                {state === "loading" ? "…" : S.label}
              </p>
              <p className="text-xs text-white/45">
                {state === "error"
                  ? "Live-Daten momentan nicht abrufbar"
                  : "aktualisiert beim Laden der Seite"}
              </p>
            </div>
          </div>
          <p className="mt-5 text-sm leading-relaxed text-white/65">{S.text}</p>
          <div className="mt-6 grid grid-cols-2 gap-3">
            <div className="rounded-2xl border border-white/10 p-3">
              <p className="text-[11px] text-white/45">Kälteste Nacht (7 T.)</p>
              <p className="mt-1 flex items-center gap-1.5 text-xl font-extrabold">
                <Thermometer className="size-4 text-frost-300" />
                {days.length ? `${Math.min(...days.map((d) => d.min)).toFixed(0)} °C` : "–"}
              </p>
            </div>
            <div className="rounded-2xl border border-white/10 p-3">
              <p className="text-[11px] text-white/45">Schnee (Summe)</p>
              <p className="mt-1 flex items-center gap-1.5 text-xl font-extrabold">
                <Snowflake className="size-4 text-frost-300" />
                {days.length
                  ? `${days.reduce((a, d) => a + d.snow, 0).toFixed(1)} cm`
                  : "–"}
              </p>
            </div>
          </div>
        </motion.div>

        <div className="glass rounded-3xl p-6 sm:p-7">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            7-Tage-Einsatzprognose
          </p>
          <div className="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-7">
            {(days.length ? days : Array.from({ length: 7 })).map((d, i) => {
              const day = d as Day | undefined;
              const alert = day ? day.snow > 0.2 || day.min <= 0 : false;
              return (
                <motion.div
                  key={day?.date ?? i}
                  initial={{ opacity: 0, y: 14 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.05 }}
                  className={`rounded-2xl border p-3 text-center ${
                    alert ? "border-frost-400/50 bg-frost-500/10" : "border-white/10 bg-white/[0.02]"
                  }`}
                >
                  <p className="text-[11px] font-semibold uppercase tracking-wide text-white/45">
                    {day
                      ? new Date(day.date).toLocaleDateString("de-DE", { weekday: "short" })
                      : "–"}
                  </p>
                  <p className="mt-2 text-lg font-extrabold">
                    {day ? `${Math.round(day.max)}°` : "–"}
                  </p>
                  <p className="text-xs text-white/45">
                    {day ? `${Math.round(day.min)}°` : ""}
                  </p>
                  {day && day.snow > 0 && (
                    <p className="mt-2 inline-flex items-center gap-1 rounded-lg bg-frost-500/20 px-2 py-0.5 text-[10px] font-bold text-frost-300">
                      <Snowflake className="size-3" />
                      {day.snow.toFixed(1)}
                    </p>
                  )}
                </motion.div>
              );
            })}
          </div>
          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            {[
              ["04:00 Uhr", "Start der ersten Räumtour"],
              ["< 2 Std.", "Reaktionszeit bei Neuschnee"],
              ["Protokoll", "Foto + GPS je Einsatz"],
            ].map(([k, v]) => (
              <div key={v} className="rounded-2xl border border-white/10 p-4">
                <p className="text-lg font-extrabold text-leaf-400">{k}</p>
                <p className="text-xs text-white/55">{v}</p>
              </div>
            ))}
          </div>
          <p className="mt-4 text-[11px] text-white/35">
            Wetterdaten: Open-Meteo. Die Ampel ist ein Service-Indikator, keine amtliche Warnung.
          </p>
        </div>
      </div>
    </Section>
  );
}
