"use client";

import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Leaf, Building2, Snowflake, ArrowRight, Sparkles } from "lucide-react";
import type { Season } from "@/components/three/SeasonIsland";

const SeasonIsland = dynamic(() => import("@/components/three/SeasonIsland"), {
  ssr: false,
  loading: () => (
    <div className="grid h-full w-full place-items-center">
      <div className="size-16 animate-spin rounded-full border-2 border-white/10 border-t-leaf-500" />
    </div>
  ),
});

const MODES = [
  {
    id: 0 as Season,
    label: "Gartenpflege",
    icon: Leaf,
    headline: "Grün, das gepflegt aussieht.",
    text: "Rasen, Hecken, Beete, Baumschnitt und Laub – im festen Rhythmus, dokumentiert nach jedem Einsatz.",
    accent: "text-leaf-400",
    ring: "ring-leaf-500/40",
  },
  {
    id: 1 as Season,
    label: "Objektpflege",
    icon: Building2,
    headline: "Objekte, die glänzen.",
    text: "Treppenhaus, Außenanlage, Tiefgarage, Müllstandsplatz – ein Team, ein Ansprechpartner, ein Preis.",
    accent: "text-frost-300",
    ring: "ring-frost-500/40",
  },
  {
    id: 2 as Season,
    label: "Winterdienst",
    icon: Snowflake,
    headline: "Geräumt, bevor der Tag beginnt.",
    text: "Räum- und Streupflicht rechtssicher übernommen – mit Einsatzprotokoll und GPS-Zeitstempel.",
    accent: "text-frost-400",
    ring: "ring-frost-400/40",
  },
];

export default function Hero() {
  const [season, setSeason] = useState<Season>(0);
  const [auto, setAuto] = useState(true);

  useEffect(() => {
    if (!auto) return;
    const t = setInterval(() => {
      setSeason((s) => (((s + 1) % 3) as Season));
    }, 5200);
    return () => clearInterval(t);
  }, [auto]);

  const mode = MODES[season];

  return (
    <section id="top" className="relative min-h-[100svh] overflow-hidden pt-28">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute left-1/2 top-[-18%] h-[520px] w-[820px] -translate-x-1/2 rounded-full bg-leaf-600/20 blur-[140px]" />
        <div className="absolute bottom-[-10%] right-[-10%] h-[420px] w-[520px] rounded-full bg-frost-500/15 blur-[130px]" />
      </div>

      <div className="absolute inset-0 top-20">
        <SeasonIsland season={season} className="h-full w-full" />
      </div>
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-72 bg-gradient-to-t from-ink-950 via-ink-950/80 to-transparent" />

      <div className="relative z-10 mx-auto grid max-w-7xl gap-10 px-4 pb-20 lg:grid-cols-[minmax(0,1fr)_380px]">
        <div className="max-w-2xl">
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-semibold tracking-wide text-white/80 backdrop-blur"
          >
            <Sparkles className="size-3.5 text-leaf-400" />
            365 Tage · ein Partner · Festpreis-Garantie
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.05 }}
            className="mt-5 text-balance text-5xl font-extrabold leading-[0.95] tracking-tight sm:text-6xl lg:text-7xl"
          >
            <span className="text-gradient">Ganzjährig</span> gepflegt.
            <br />
            Ohne Wenn und Aber.
          </motion.h1>

          <div className="mt-6 min-h-[92px]">
            <AnimatePresence mode="wait">
              <motion.div
                key={mode.id}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                transition={{ duration: 0.35 }}
              >
                <p className={`text-xl font-bold ${mode.accent}`}>{mode.headline}</p>
                <p className="mt-2 max-w-xl text-base leading-relaxed text-white/70">
                  {mode.text}
                </p>
              </motion.div>
            </AnimatePresence>
          </div>

          <div className="mt-7 flex flex-wrap items-center gap-3">
            <a
              href="#rechner"
              className="group inline-flex items-center gap-2 rounded-2xl bg-leaf-500 px-6 py-3.5 font-bold text-ink-950 shadow-xl shadow-leaf-600/25 transition hover:bg-leaf-400"
            >
              Preis in 60 Sekunden
              <ArrowRight className="size-4 transition group-hover:translate-x-1" />
            </a>
            <a
              href="#leistungen"
              className="inline-flex items-center gap-2 rounded-2xl border border-white/15 px-6 py-3.5 font-semibold text-white/85 transition hover:border-white/35 hover:bg-white/5"
            >
              Leistungen ansehen
            </a>
          </div>

          <dl className="mt-10 grid max-w-lg grid-cols-3 gap-4">
            {[
              ["< 2 Std.", "Reaktionszeit Winter"],
              ["100 %", "Festpreis, keine Nachträge"],
              ["1", "Ansprechpartner statt drei"],
            ].map(([k, v]) => (
              <div key={v} className="rounded-2xl border border-white/10 bg-white/[0.03] p-3">
                <dt className="text-2xl font-extrabold text-leaf-400">{k}</dt>
                <dd className="mt-0.5 text-xs leading-snug text-white/60">{v}</dd>
              </div>
            ))}
          </dl>
        </div>

        <div className="flex items-end lg:justify-end">
          <div className="glass w-full rounded-3xl p-3">
            <p className="px-2 pb-2 pt-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-white/50">
              Szene wechseln
            </p>
            <div className="grid gap-2">
              {MODES.map((m) => {
                const Icon = m.icon;
                const active = m.id === season;
                return (
                  <button
                    key={m.id}
                    type="button"
                    onClick={() => {
                      setSeason(m.id);
                      setAuto(false);
                    }}
                    className={`flex items-center gap-3 rounded-2xl border px-4 py-3 text-left transition ${
                      active
                        ? `border-transparent bg-white/10 ring-2 ${m.ring}`
                        : "border-white/10 hover:bg-white/5"
                    }`}
                  >
                    <span
                      className={`grid size-9 place-items-center rounded-xl ${
                        active ? "bg-leaf-500 text-ink-950" : "bg-white/5 text-white/70"
                      }`}
                    >
                      <Icon className="size-4.5" />
                    </span>
                    <span className="flex-1">
                      <span className="block text-sm font-bold">{m.label}</span>
                      <span className="block text-[11px] text-white/50">
                        {active ? "3D-Szene aktiv" : "Ansehen"}
                      </span>
                    </span>
                  </button>
                );
              })}
            </div>
            <p className="px-2 pb-1 pt-3 text-[11px] text-white/40">
              Tipp: Maus über die Szene bewegen – das Modell folgt dir.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
