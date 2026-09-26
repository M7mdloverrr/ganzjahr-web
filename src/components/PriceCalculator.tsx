"use client";

import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Leaf, Building2, Snowflake, Check, ArrowRight } from "lucide-react";
import Section from "@/components/Section";
import { site } from "@/lib/site";

type ServiceKey = "garten" | "objekt" | "winter";

const SERVICES: {
  key: ServiceKey;
  label: string;
  icon: typeof Leaf;
  unit: string;
  hint: string;
}[] = [
  { key: "garten", label: "Gartenpflege", icon: Leaf, unit: "m² Grünfläche", hint: "Rasen, Hecke, Beete" },
  { key: "objekt", label: "Objektpflege", icon: Building2, unit: "m² Grünfläche", hint: "Treppenhaus, Außenanlage" },
  { key: "winter", label: "Winterdienst", icon: Snowflake, unit: "m² Grünfläche", hint: "Räumen & Streuen" },
];

const INTERVALS = [
  { key: "woche", label: "wöchentlich", factor: 1.9 },
  { key: "zwei", label: "14-tägig", factor: 1.35 },
  { key: "monat", label: "monatlich", factor: 1.0 },
  { key: "quartal", label: "nach Bedarf", factor: 0.78 },
] as const;

export default function PriceCalculator() {
  const [selected, setSelected] = useState<ServiceKey[]>(["garten", "winter"]);
  const [area, setArea] = useState(450);
  const [units, setUnits] = useState(12);
  const [intervalKey, setIntervalKey] = useState<(typeof INTERVALS)[number]["key"]>("zwei");
  const [protocol, setProtocol] = useState(true);
  const [express, setExpress] = useState(false);

  const factor = INTERVALS.find((i) => i.key === intervalKey)!.factor;

  const price = useMemo(() => {
    let p = 0;
    if (selected.includes("garten")) p += 48 + area * 0.085;
    if (selected.includes("objekt")) p += 62 + units * 7.4;
    if (selected.includes("winter")) p += 79 + area * 0.045;
    p *= factor;
    if (selected.length >= 2) p *= 0.91; // Bündelvorteil
    if (selected.length === 3) p *= 0.95;
    if (protocol) p += 14;
    if (express) p *= 1.12;
    return Math.round(p / 5) * 5;
  }, [selected, area, units, factor, protocol, express]);

  const bundleSaving = selected.length >= 2;

  const toggle = (k: ServiceKey) =>
    setSelected((s) => (s.includes(k) ? s.filter((x) => x !== k) : [...s, k]));

  const mailBody = encodeURIComponent(
    `Hallo GanzJahr-Team,\n\nich hätte gern ein Festpreis-Angebot.\n\nLeistungen: ${
      selected.length ? selected.join(", ") : "—"
    }\nGrünfläche: ${area} m²\nWohneinheiten: ${units}\nIntervall: ${
      INTERVALS.find((i) => i.key === intervalKey)!.label
    }\nDigitales Protokoll: ${protocol ? "ja" : "nein"}\nExpress-Bereitschaft: ${
      express ? "ja" : "nein"
    }\nRichtwert laut Rechner: ${price} € / Monat\n\nObjektadresse: \nName: \nTelefon: \n`,
  );

  return (
    <Section
      id="rechner"
      eyebrow="Festpreis-Rechner"
      title="Dein Preis. Sofort. Ohne Vertretertermin."
      subtitle="Bei den meisten Anbietern heißt es „Wir melden uns“. Hier siehst du den Richtwert live – und schickst ihn mit einem Klick als Angebotsanfrage ab."
    >
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1.25fr)_minmax(0,1fr)]">
        <div className="glass rounded-3xl p-6 sm:p-8">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            1 · Leistungen
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            {SERVICES.map((s) => {
              const I = s.icon;
              const on = selected.includes(s.key);
              return (
                <button
                  key={s.key}
                  type="button"
                  onClick={() => toggle(s.key)}
                  className={`rounded-2xl border p-4 text-left transition ${
                    on
                      ? "border-leaf-500/70 bg-leaf-500/10"
                      : "border-white/10 bg-white/[0.02] hover:border-white/25"
                  }`}
                >
                  <span className="flex items-center justify-between">
                    <I className={`size-5 ${on ? "text-leaf-400" : "text-white/50"}`} />
                    <span
                      className={`grid size-5 place-items-center rounded-md border ${
                        on ? "border-leaf-400 bg-leaf-500 text-ink-950" : "border-white/20"
                      }`}
                    >
                      {on && <Check className="size-3.5" strokeWidth={3} />}
                    </span>
                  </span>
                  <span className="mt-3 block text-sm font-bold">{s.label}</span>
                  <span className="block text-[11px] text-white/45">{s.hint}</span>
                </button>
              );
            })}
          </div>

          <p className="mt-8 text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            2 · Objektgröße
          </p>
          <div className="mt-4 grid gap-6 sm:grid-cols-2">
            <label className="block">
              <span className="flex items-baseline justify-between text-sm text-white/70">
                Grünfläche
                <b className="text-leaf-400">{area} m²</b>
              </span>
              <input
                type="range"
                min={50}
                max={5000}
                step={50}
                value={area}
                onChange={(e) => setArea(+e.target.value)}
                className="mt-3 w-full"
              />
            </label>
            <label className="block">
              <span className="flex items-baseline justify-between text-sm text-white/70">
                Wohn-/Gewerbeeinheiten
                <b className="text-leaf-400">{units}</b>
              </span>
              <input
                type="range"
                min={1}
                max={200}
                step={1}
                value={units}
                onChange={(e) => setUnits(+e.target.value)}
                className="mt-3 w-full"
              />
            </label>
          </div>

          <p className="mt-8 text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            3 · Intervall
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            {INTERVALS.map((i) => (
              <button
                key={i.key}
                type="button"
                onClick={() => setIntervalKey(i.key)}
                className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                  intervalKey === i.key
                    ? "border-leaf-500 bg-leaf-500 text-ink-950"
                    : "border-white/10 text-white/70 hover:border-white/30"
                }`}
              >
                {i.label}
              </button>
            ))}
          </div>

          <p className="mt-8 text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            4 · Extras
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {[
              {
                on: protocol,
                set: setProtocol,
                title: "Digitales Einsatzprotokoll",
                desc: "Fotos + Zeitstempel im Monatsbericht",
              },
              {
                on: express,
                set: setExpress,
                title: "Express-Bereitschaft",
                desc: "Reaktion < 2 Std. auch am Wochenende",
              },
            ].map((x) => (
              <button
                key={x.title}
                type="button"
                onClick={() => x.set(!x.on)}
                className={`flex items-start gap-3 rounded-2xl border p-4 text-left transition ${
                  x.on ? "border-leaf-500/70 bg-leaf-500/10" : "border-white/10 hover:border-white/25"
                }`}
              >
                <span
                  className={`mt-0.5 grid size-5 shrink-0 place-items-center rounded-md border ${
                    x.on ? "border-leaf-400 bg-leaf-500 text-ink-950" : "border-white/20"
                  }`}
                >
                  {x.on && <Check className="size-3.5" strokeWidth={3} />}
                </span>
                <span>
                  <span className="block text-sm font-bold">{x.title}</span>
                  <span className="block text-[11px] text-white/45">{x.desc}</span>
                </span>
              </button>
            ))}
          </div>
        </div>

        <div className="lg:sticky lg:top-28 lg:self-start">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="relative overflow-hidden rounded-3xl border border-leaf-500/25 bg-gradient-to-b from-leaf-600/20 to-ink-900 p-7"
          >
            <div className="pointer-events-none absolute -right-16 -top-16 size-52 rounded-full bg-leaf-500/25 blur-3xl" />
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/55">
              Dein Richtwert
            </p>
            <div className="mt-3 flex items-end gap-2">
              <motion.span
                key={price}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-6xl font-extrabold tracking-tight"
              >
                {selected.length ? price : 0}
              </motion.span>
              <span className="pb-2 text-xl font-bold text-white/70">€ / Monat</span>
            </div>
            <p className="mt-1 text-xs text-white/50">
              netto, inkl. An-/Abfahrt im Umkreis von {site.serviceRadiusKm} km
            </p>

            {bundleSaving && (
              <p className="mt-4 inline-flex items-center gap-2 rounded-xl bg-leaf-500/15 px-3 py-2 text-xs font-semibold text-leaf-300">
                <Check className="size-4" /> Bündelvorteil aktiv –{" "}
                {selected.length === 3 ? "13,5" : "9"} % gespart
              </p>
            )}

            <ul className="mt-6 space-y-2 text-sm text-white/70">
              {[
                "Festpreis für 12 Monate garantiert",
                "Keine Nachträge, kein Kleingedrucktes",
                "Monatlich kündbar nach dem 1. Jahr",
              ].map((t) => (
                <li key={t} className="flex gap-2">
                  <Check className="mt-0.5 size-4 shrink-0 text-leaf-400" />
                  {t}
                </li>
              ))}
            </ul>

            <a
              href={`mailto:${site.email}?subject=${encodeURIComponent(
                "Festpreis-Anfrage über die Website",
              )}&body=${mailBody}`}
              className="group mt-7 flex w-full items-center justify-center gap-2 rounded-2xl bg-leaf-500 px-5 py-4 font-bold text-ink-950 transition hover:bg-leaf-400"
            >
              Angebot verbindlich anfragen
              <ArrowRight className="size-4 transition group-hover:translate-x-1" />
            </a>
            <p className="mt-3 text-center text-[11px] text-white/40">
              Unverbindlicher Richtwert. Das schriftliche Angebot kommt innerhalb von 24 Std.
            </p>
          </motion.div>
        </div>
      </div>
    </Section>
  );
}
