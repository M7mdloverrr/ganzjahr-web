"use client";

import { motion } from "framer-motion";
import { AlarmClock, Receipt, Camera } from "lucide-react";
import TiltCard from "@/components/TiltCard";
import Section from "@/components/Section";

const ITEMS = [
  {
    icon: AlarmClock,
    kicker: "07:00-Garantie",
    title: "Nach 7 Uhr geräumt? Einsatz kostenlos.",
    text: "Bei angekündigtem Schneefall sind Gehwege und Zufahrten vor Arbeitsbeginn frei. Schaffen wir das nicht, streichen wir die Position von der Rechnung.",
  },
  {
    icon: Receipt,
    kicker: "Festpreis-Pakt",
    title: "12 Monate derselbe Preis – oder wir zahlen die Differenz.",
    text: "Keine Zuschläge für Extra-Touren im Ausnahmewinter, keine Sprit- oder Streugut-Nachträge. Was im Angebot steht, steht auf der Rechnung.",
  },
  {
    icon: Camera,
    kicker: "Beweis-Protokoll",
    title: "Jeder Einsatz mit Foto, Uhrzeit und GPS.",
    text: "Deine Verwaltung bekommt monatlich ein PDF, das vor Gericht als Nachweis der Verkehrssicherungspflicht taugt. Ohne Nachfragen, ohne Zettelwirtschaft.",
  },
];

export default function Guarantees() {
  return (
    <Section
      eyebrow="Unsere Garantien"
      title="Drei Versprechen, die andere nicht schriftlich geben."
      subtitle="Wir haben aufgeschrieben, wofür wir haften. Das ist der Unterschied zwischen einem Dienstleister und einem Partner."
    >
      <div className="grid gap-5 lg:grid-cols-3">
        {ITEMS.map((it, i) => {
          const I = it.icon;
          return (
            <motion.div
              key={it.kicker}
              initial={{ opacity: 0, y: 26 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ delay: i * 0.08 }}
            >
              <TiltCard className="h-full" max={7}>
                <div className="relative h-full overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-ink-800 to-ink-900 p-7">
                  <span className="absolute -right-6 -top-8 text-[110px] font-black leading-none text-white/[0.04]">
                    0{i + 1}
                  </span>
                  <I className="size-7 text-leaf-400" />
                  <p className="mt-5 text-xs font-bold uppercase tracking-[0.2em] text-leaf-400">
                    {it.kicker}
                  </p>
                  <h3 className="mt-2 text-xl font-extrabold leading-snug">{it.title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-white/60">{it.text}</p>
                </div>
              </TiltCard>
            </motion.div>
          );
        })}
      </div>
    </Section>
  );
}
