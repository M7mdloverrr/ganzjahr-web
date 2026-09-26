"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Leaf, Building2, Snowflake } from "lucide-react";
import Section from "@/components/Section";

type Task = { label: string; type: "garten" | "objekt" | "winter" };

const MONTHS: { m: string; long: string; tasks: Task[] }[] = [
  {
    m: "Jan",
    long: "Januar",
    tasks: [
      { label: "Räum- & Streudienst, Bereitschaft 24/7", type: "winter" },
      { label: "Treppenhausreinigung im Winterintervall", type: "objekt" },
      { label: "Gehölzschnitt bei Frostfreiheit", type: "garten" },
    ],
  },
  {
    m: "Feb",
    long: "Februar",
    tasks: [
      { label: "Winterdienst & Streugutnachschub", type: "winter" },
      { label: "Obstbaumschnitt", type: "garten" },
      { label: "Kontrollgang Dachrinnen & Abläufe", type: "objekt" },
    ],
  },
  {
    m: "Mär",
    long: "März",
    tasks: [
      { label: "Frühjahrsputz Außenanlage", type: "objekt" },
      { label: "Rasen vertikutieren & düngen", type: "garten" },
      { label: "Winterdienst-Abbau, Streugut kehren", type: "winter" },
    ],
  },
  {
    m: "Apr",
    long: "April",
    tasks: [
      { label: "Erster Rasenschnitt, Kantenstich", type: "garten" },
      { label: "Beete anlegen & bepflanzen", type: "garten" },
      { label: "Glasreinigung Eingangsbereiche", type: "objekt" },
    ],
  },
  {
    m: "Mai",
    long: "Mai",
    tasks: [
      { label: "Mähintervall 14-tägig", type: "garten" },
      { label: "Heckenschnitt (Formschnitt)", type: "garten" },
      { label: "Müllstandsplatz-Grundreinigung", type: "objekt" },
    ],
  },
  {
    m: "Jun",
    long: "Juni",
    tasks: [
      { label: "Bewässerung & Unkrautregulierung", type: "garten" },
      { label: "Spielplatz-Sichtkontrolle", type: "objekt" },
      { label: "Fassadengrün zurückschneiden", type: "garten" },
    ],
  },
  {
    m: "Jul",
    long: "Juli",
    tasks: [
      { label: "Hitzeplan: Bewässerung früh morgens", type: "garten" },
      { label: "Tiefgaragenreinigung", type: "objekt" },
      { label: "Rasen-Nachsaat auf Trockenstellen", type: "garten" },
    ],
  },
  {
    m: "Aug",
    long: "August",
    tasks: [
      { label: "Zweiter Heckenschnitt", type: "garten" },
      { label: "Wegebeläge abkehren & Fugen", type: "objekt" },
      { label: "Urlaubsvertretung Hausmeister", type: "objekt" },
    ],
  },
  {
    m: "Sep",
    long: "September",
    tasks: [
      { label: "Herbstdüngung, Rasenregeneration", type: "garten" },
      { label: "Winterdienst-Vertrag prüfen & fixieren", type: "winter" },
      { label: "Laubschutz an Abläufen montieren", type: "objekt" },
    ],
  },
  {
    m: "Okt",
    long: "Oktober",
    tasks: [
      { label: "Laubräumung im Kurzintervall", type: "garten" },
      { label: "Streugutdepots befüllen", type: "winter" },
      { label: "Frostschutz Außenwasserhähne", type: "objekt" },
    ],
  },
  {
    m: "Nov",
    long: "November",
    tasks: [
      { label: "Winterdienst-Bereitschaft startet 01.11.", type: "winter" },
      { label: "Rückschnitt Stauden, letzte Laubtour", type: "garten" },
      { label: "Beleuchtungskontrolle Außenanlage", type: "objekt" },
    ],
  },
  {
    m: "Dez",
    long: "Dezember",
    tasks: [
      { label: "Räumen & Streuen inkl. Feiertage", type: "winter" },
      { label: "Winterprotokoll digital an Verwaltung", type: "winter" },
      { label: "Treppenhaus-Intensivreinigung", type: "objekt" },
    ],
  },
];

const META = {
  garten: { icon: Leaf, color: "text-leaf-400", ring: "bg-leaf-500" },
  objekt: { icon: Building2, color: "text-white/80", ring: "bg-ink-400" },
  winter: { icon: Snowflake, color: "text-frost-300", ring: "bg-frost-500" },
} as const;

export default function YearWheel() {
  const [active, setActive] = useState(new Date().getMonth());
  const [auto, setAuto] = useState(true);

  useEffect(() => {
    if (!auto) return;
    const t = setInterval(() => setActive((a) => (a + 1) % 12), 3400);
    return () => clearInterval(t);
  }, [auto]);

  const rotation = -active * 30;
  const cur = MONTHS[active];

  return (
    <Section
      id="jahresrad"
      eyebrow="Das Jahresrad"
      title="Wir arbeiten nach Kalender – nicht nach Zuruf."
      subtitle="Dreh am Rad: Für jeden Monat steht fest, was auf deinem Objekt passiert. Dieser Plan ist Teil des Vertrags – kein Einsatz wird 'vergessen'."
    >
      <div className="grid items-center gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <div className="relative mx-auto aspect-square w-full max-w-[460px]">
          <div className="absolute inset-0 rounded-full bg-[conic-gradient(from_0deg,var(--color-leaf-600)_0deg,var(--color-leaf-400)_90deg,var(--color-frost-400)_200deg,var(--color-frost-500)_280deg,var(--color-leaf-600)_360deg)] opacity-25 blur-2xl" />
          <motion.div
            className="absolute inset-0"
            animate={{ rotate: rotation }}
            transition={{ type: "spring", stiffness: 60, damping: 16 }}
          >
            {MONTHS.map((mo, i) => {
              const angle = i * 30;
              const isActive = i === active;
              return (
                <button
                  key={mo.m}
                  type="button"
                  onClick={() => {
                    setActive(i);
                    setAuto(false);
                  }}
                  className="absolute left-1/2 top-1/2 origin-center"
                  style={{
                    transform: `rotate(${angle}deg) translateY(calc(-1 * min(38vw, 186px))) rotate(${-angle - rotation}deg)`,
                  }}
                >
                  <span
                    className={`grid size-14 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-2xl border text-sm font-bold transition ${
                      isActive
                        ? "border-leaf-400 bg-leaf-500 text-ink-950 shadow-xl shadow-leaf-500/30"
                        : "border-white/10 bg-ink-900/80 text-white/65 hover:border-white/30"
                    }`}
                  >
                    {mo.m}
                  </span>
                </button>
              );
            })}
          </motion.div>

          <div className="absolute inset-[18%] grid place-items-center rounded-full border border-white/10 bg-ink-900/70 backdrop-blur">
            <AnimatePresence mode="wait">
              <motion.div
                key={cur.long}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 1.06 }}
                transition={{ duration: 0.25 }}
                className="text-center"
              >
                <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-white/45">
                  Einsatzmonat
                </p>
                <p className="mt-1 text-3xl font-extrabold tracking-tight">{cur.long}</p>
                <p className="mt-1 text-xs text-leaf-400">{cur.tasks.length} feste Leistungen</p>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>

        <div>
          <AnimatePresence mode="wait">
            <motion.ul
              key={cur.long}
              initial={{ opacity: 0, x: 18 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -18 }}
              transition={{ duration: 0.3 }}
              className="space-y-3"
            >
              {cur.tasks.map((t) => {
                const M = META[t.type];
                const I = M.icon;
                return (
                  <li
                    key={t.label}
                    className="glass flex items-center gap-4 rounded-2xl px-5 py-4"
                  >
                    <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-ink-950/60 ring-1 ring-white/10">
                      <I className={`size-5 ${M.color}`} />
                    </span>
                    <span className="text-sm font-medium text-white/80">{t.label}</span>
                  </li>
                );
              })}
            </motion.ul>
          </AnimatePresence>
          <p className="mt-5 text-sm text-white/50">
            Jede erledigte Position wird fotografiert und landet automatisch im
            Monatsbericht deiner Hausverwaltung.
          </p>
        </div>
      </div>
    </Section>
  );
}
