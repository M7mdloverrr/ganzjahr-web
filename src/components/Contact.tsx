"use client";

import { useState } from "react";
import { Mail, Phone, MapPin, Send, Check } from "lucide-react";
import Section from "@/components/Section";
import { site } from "@/lib/site";

const SERVICES = ["Gartenpflege", "Objektpflege", "Winterdienst", "Komplettpaket"];

export default function Contact() {
  const [service, setService] = useState("Komplettpaket");
  const [name, setName] = useState("");
  const [contact, setContact] = useState("");
  const [object, setObject] = useState("");
  const [message, setMessage] = useState("");

  const href = `mailto:${site.email}?subject=${encodeURIComponent(
    `Anfrage ${service}`,
  )}&body=${encodeURIComponent(
    `Leistung: ${service}\nName: ${name}\nKontakt: ${contact}\nObjekt: ${object}\n\n${message}\n`,
  )}`;

  const ready = name.trim() !== "" && contact.trim() !== "";

  return (
    <Section
      id="kontakt"
      eyebrow="Kontakt"
      title="Objektcheck anfragen – kostenlos und unverbindlich."
      subtitle="Antwort am selben Werktag. Für Winterdienst-Anfragen ab Oktober empfehlen wir frühzeitige Reservierung – die Touren sind begrenzt."
    >
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px]">
        <div className="glass rounded-3xl p-6 sm:p-8">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/45">
            Leistung
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            {SERVICES.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => setService(s)}
                className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                  service === s
                    ? "border-leaf-500 bg-leaf-500 text-ink-950"
                    : "border-white/10 text-white/70 hover:border-white/30"
                }`}
              >
                {s}
              </button>
            ))}
          </div>

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
            {[
              { label: "Name *", value: name, set: setName, ph: "Max Mustermann" },
              {
                label: "E-Mail oder Telefon *",
                value: contact,
                set: setContact,
                ph: "max@beispiel.de",
              },
            ].map((f) => (
              <label key={f.label} className="block">
                <span className="text-sm text-white/60">{f.label}</span>
                <input
                  value={f.value}
                  onChange={(e) => f.set(e.target.value)}
                  placeholder={f.ph}
                  className="mt-2 w-full rounded-xl border border-white/10 bg-ink-950/60 px-4 py-3 text-sm outline-none transition placeholder:text-white/25 focus:border-leaf-500"
                />
              </label>
            ))}
          </div>

          <label className="mt-4 block">
            <span className="text-sm text-white/60">Objektadresse</span>
            <input
              value={object}
              onChange={(e) => setObject(e.target.value)}
              placeholder="Musterstraße 1, 12345 Musterstadt"
              className="mt-2 w-full rounded-xl border border-white/10 bg-ink-950/60 px-4 py-3 text-sm outline-none transition placeholder:text-white/25 focus:border-leaf-500"
            />
          </label>

          <label className="mt-4 block">
            <span className="text-sm text-white/60">Worum geht es?</span>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={4}
              placeholder="z. B. 1.200 m² Grünfläche, 18 Einheiten, Winterdienst ab November"
              className="mt-2 w-full resize-none rounded-xl border border-white/10 bg-ink-950/60 px-4 py-3 text-sm outline-none transition placeholder:text-white/25 focus:border-leaf-500"
            />
          </label>

          <a
            href={ready ? href : undefined}
            aria-disabled={!ready}
            className={`mt-6 inline-flex items-center gap-2 rounded-2xl px-6 py-3.5 font-bold transition ${
              ready
                ? "bg-leaf-500 text-ink-950 hover:bg-leaf-400"
                : "pointer-events-none bg-white/10 text-white/35"
            }`}
          >
            <Send className="size-4" />
            Anfrage senden
          </a>
          <p className="mt-3 text-[11px] text-white/35">
            Öffnet dein E-Mail-Programm mit allen Angaben. Kein Tracking, keine Weitergabe an Dritte.
          </p>
        </div>

        <div className="space-y-4">
          {[
            { icon: Phone, label: "Telefon", value: site.phone, href: site.phoneHref },
            { icon: Mail, label: "E-Mail", value: site.email, href: `mailto:${site.email}` },
            { icon: MapPin, label: "Einsatzgebiet", value: `${site.city} + ${site.serviceRadiusKm} km` },
          ].map((c) => {
            const I = c.icon;
            const inner = (
              <>
                <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-leaf-500/15">
                  <I className="size-5 text-leaf-400" />
                </span>
                <span>
                  <span className="block text-[11px] uppercase tracking-[0.18em] text-white/40">
                    {c.label}
                  </span>
                  <span className="block text-sm font-bold">{c.value}</span>
                </span>
              </>
            );
            return c.href ? (
              <a key={c.label} href={c.href} className="glass flex items-center gap-4 rounded-2xl p-5 transition hover:border-leaf-500/50">
                {inner}
              </a>
            ) : (
              <div key={c.label} className="glass flex items-center gap-4 rounded-2xl p-5">
                {inner}
              </div>
            );
          })}

          <div className="rounded-3xl border border-leaf-500/25 bg-leaf-500/10 p-6">
            <p className="text-sm font-bold">Winterdienst 25/26</p>
            <ul className="mt-3 space-y-2 text-sm text-white/70">
              {["Touren zu 78 % vergeben", "Vertragsstart bis 15.10. möglich", "Streugutdepot inklusive"].map(
                (t) => (
                  <li key={t} className="flex gap-2">
                    <Check className="mt-0.5 size-4 shrink-0 text-leaf-400" />
                    {t}
                  </li>
                ),
              )}
            </ul>
          </div>
        </div>
      </div>
    </Section>
  );
}
