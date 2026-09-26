"use client";

import { motion } from "framer-motion";
import { Quote, Star } from "lucide-react";
import Section from "@/components/Section";

const STATS = [
  ["120+", "betreute Einheiten"],
  ["1.400", "Einsätze pro Jahr"],
  ["0", "verpasste Räumtouren 24/25"],
  ["4,9", "Ø Bewertung"],
];

const VOICES = [
  {
    text: "Vorher drei Firmen, drei Rechnungen, drei Ausreden. Jetzt ein Ansprechpartner, der auch im Januar um 5 Uhr rangeht.",
    name: "Hausverwaltung, 42 Einheiten",
  },
  {
    text: "Das Monatsprotokoll mit Fotos hat uns bei einer Haftungsfrage nach einem Sturz sofort entlastet.",
    name: "WEG-Verwaltungsbeirat",
  },
  {
    text: "Der Preis stand von Anfang an fest – nach einem Winter mit doppelt so viel Schnee kam trotzdem keine Nachforderung.",
    name: "Eigentümer Gewerbeobjekt",
  },
];

const LOGOS = [
  "Hausverwaltung Nord",
  "WEG Lindenhof",
  "Gewerbepark Süd",
  "Stadtwohnen eG",
  "Immobilien Kranz",
  "Quartier 12",
];

export default function References() {
  return (
    <Section
      id="referenzen"
      eyebrow="Referenzen"
      title="Verwaltungen bleiben – weil nichts liegen bleibt."
    >
      <div className="grid gap-4 sm:grid-cols-4">
        {STATS.map(([k, v], i) => (
          <motion.div
            key={v}
            initial={{ opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.06 }}
            className="glass rounded-3xl p-6"
          >
            <p className="text-4xl font-extrabold tracking-tight text-leaf-400">{k}</p>
            <p className="mt-1 text-sm text-white/55">{v}</p>
          </motion.div>
        ))}
      </div>

      <div className="mt-6 grid gap-5 lg:grid-cols-3">
        {VOICES.map((v, i) => (
          <motion.figure
            key={v.name}
            initial={{ opacity: 0, y: 22 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.08 }}
            className="relative overflow-hidden rounded-3xl border border-white/10 bg-ink-900/70 p-7"
          >
            <Quote className="size-7 text-leaf-500/60" />
            <blockquote className="mt-4 text-[15px] leading-relaxed text-white/75">
              {v.text}
            </blockquote>
            <figcaption className="mt-5 flex items-center justify-between border-t border-white/10 pt-4">
              <span className="text-xs font-semibold text-white/50">{v.name}</span>
              <span className="flex gap-0.5">
                {Array.from({ length: 5 }).map((_, s) => (
                  <Star key={s} className="size-3.5 fill-leaf-400 text-leaf-400" />
                ))}
              </span>
            </figcaption>
          </motion.figure>
        ))}
      </div>

      <div className="edge-fade mt-10 overflow-hidden">
        <div className="flex w-max animate-marquee gap-10 opacity-45">
          {[...LOGOS, ...LOGOS].map((l, i) => (
            <span
              key={`${l}-${i}`}
              className="whitespace-nowrap text-lg font-bold uppercase tracking-[0.18em] text-white/70"
            >
              {l}
            </span>
          ))}
        </div>
      </div>
    </Section>
  );
}
