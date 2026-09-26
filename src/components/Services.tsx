"use client";

import { motion } from "framer-motion";
import {
  Leaf,
  Building2,
  Snowflake,
  Scissors,
  Trash2,
  SprayCan,
  TreeDeciduous,
  Sun,
  ShieldCheck,
} from "lucide-react";
import TiltCard from "@/components/TiltCard";
import Section from "@/components/Section";

const GROUPS = [
  {
    icon: Leaf,
    title: "Gartenpflege",
    color: "from-leaf-500/25 to-transparent",
    badge: "März – November",
    items: [
      { icon: Scissors, text: "Rasenmähen, Vertikutieren, Kantenschnitt" },
      { icon: TreeDeciduous, text: "Hecken-, Strauch- & Baumschnitt" },
      { icon: Sun, text: "Beetpflege, Bewässerung, Neupflanzung" },
    ],
  },
  {
    icon: Building2,
    title: "Objektpflege",
    color: "from-frost-500/25 to-transparent",
    badge: "Ganzjährig",
    items: [
      { icon: SprayCan, text: "Treppenhaus- & Glasreinigung" },
      { icon: Trash2, text: "Müllstandsplatz, Tonnenservice" },
      { icon: ShieldCheck, text: "Außenanlage, Tiefgarage, Kontrollgänge" },
    ],
  },
  {
    icon: Snowflake,
    title: "Winterdienst",
    color: "from-frost-400/25 to-transparent",
    badge: "November – März",
    items: [
      { icon: Snowflake, text: "Räumen & Streuen ab 04:00 Uhr" },
      { icon: ShieldCheck, text: "Übernahme der Verkehrssicherungspflicht" },
      { icon: Sun, text: "Einsatzprotokoll mit Foto & Zeitstempel" },
    ],
  },
];

export default function Services() {
  return (
    <Section
      id="leistungen"
      eyebrow="Leistungen"
      title="Drei Bereiche. Ein Vertrag. Null Schnittstellen."
      subtitle="Die meisten Verwaltungen jonglieren mit drei Dienstleistern. Bei uns ist es einer – mit einer Rechnung und einem Ansprechpartner, der auch am Samstag rangeht."
    >
      <div className="grid gap-5 md:grid-cols-3">
        {GROUPS.map((g, i) => {
          const Icon = g.icon;
          return (
            <motion.div
              key={g.title}
              initial={{ opacity: 0, y: 26 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ delay: i * 0.08, duration: 0.5 }}
            >
              <TiltCard className="h-full">
                <div className="glass grain relative h-full overflow-hidden rounded-3xl p-6">
                  <div
                    className={`pointer-events-none absolute inset-x-0 top-0 h-40 bg-gradient-to-b ${g.color}`}
                  />
                  <div className="relative flex items-center justify-between">
                    <span className="grid size-12 place-items-center rounded-2xl bg-ink-950/60 ring-1 ring-white/10">
                      <Icon className="size-6 text-leaf-400" />
                    </span>
                    <span className="rounded-full border border-white/10 px-3 py-1 text-[11px] font-semibold text-white/60">
                      {g.badge}
                    </span>
                  </div>
                  <h3 className="relative mt-5 text-2xl font-extrabold tracking-tight">
                    {g.title}
                  </h3>
                  <ul className="relative mt-4 space-y-3">
                    {g.items.map((it) => {
                      const I = it.icon;
                      return (
                        <li key={it.text} className="flex gap-3 text-sm text-white/72">
                          <I className="mt-0.5 size-4 shrink-0 text-leaf-500" />
                          <span className="text-white/70">{it.text}</span>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              </TiltCard>
            </motion.div>
          );
        })}
      </div>
    </Section>
  );
}
