"use client";

import { motion } from "framer-motion";
import Section from "@/components/Section";

const STEPS = [
  {
    t: "Objektcheck vor Ort",
    d: "Wir laufen das Objekt ab, messen Flächen und fotografieren den Ist-Zustand. Dauer: ca. 30 Minuten, kostenlos.",
  },
  {
    t: "Festpreis-Angebot in 24 Std.",
    d: "Du bekommst eine Position-für-Position-Kalkulation mit Jahresplan – kein Pauschaltext, sondern dein Objekt.",
  },
  {
    t: "Startwoche",
    d: "Grundreinigung bzw. Erstpflege bringt das Objekt auf Standard, bevor der reguläre Rhythmus beginnt.",
  },
  {
    t: "365 Tage Routine",
    d: "Feste Teams, fester Kalender, monatlicher Bericht. Du merkst uns nur daran, dass nichts liegen bleibt.",
  },
];

export default function Process() {
  return (
    <Section
      eyebrow="Ablauf"
      title="Von der Anfrage zur Routine – in vier Schritten."
    >
      <div className="relative">
        <div className="absolute left-[27px] top-2 hidden h-[calc(100%-1rem)] w-px bg-gradient-to-b from-leaf-500 via-leaf-600/40 to-frost-500/50 sm:block" />
        <ol className="space-y-5">
          {STEPS.map((s, i) => (
            <motion.li
              key={s.t}
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ delay: i * 0.07 }}
              className="relative flex gap-5"
            >
              <span className="z-10 grid size-14 shrink-0 place-items-center rounded-2xl border border-white/10 bg-ink-900 text-lg font-extrabold text-leaf-400">
                {i + 1}
              </span>
              <div className="glass flex-1 rounded-2xl px-6 py-5">
                <h3 className="text-lg font-bold">{s.t}</h3>
                <p className="mt-1 text-sm leading-relaxed text-white/60">{s.d}</p>
              </div>
            </motion.li>
          ))}
        </ol>
      </div>
    </Section>
  );
}
