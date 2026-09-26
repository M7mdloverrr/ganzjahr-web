import Link from "next/link";
import type { Metadata } from "next";
import { site } from "@/lib/site";

export const metadata: Metadata = { title: "Impressum | GanzJahr" };

export default function Impressum() {
  return (
    <main className="mx-auto max-w-3xl px-4 py-28">
      <Link href="/" className="text-sm text-leaf-400 hover:underline">
        ← Zurück zur Startseite
      </Link>
      <h1 className="mt-6 text-4xl font-extrabold tracking-tight">Impressum</h1>
      <div className="mt-8 space-y-6 text-sm leading-relaxed text-white/70">
        <section>
          <h2 className="text-lg font-bold text-white">Angaben gemäß § 5 DDG</h2>
          <p className="mt-2">
            {site.name} {site.tagline}
            <br />
            Inhaber: [Vor- und Nachname]
            <br />
            [Straße Hausnummer]
            <br />
            [PLZ Ort]
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">Kontakt</h2>
          <p className="mt-2">
            Telefon: {site.phone}
            <br />
            E-Mail: {site.email}
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">Umsatzsteuer-ID</h2>
          <p className="mt-2">USt-IdNr. gemäß § 27 a UStG: [DE…]</p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">
            Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV
          </h2>
          <p className="mt-2">[Vor- und Nachname, Anschrift wie oben]</p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">Streitschlichtung</h2>
          <p className="mt-2">
            Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer
            Verbraucherschlichtungsstelle teilzunehmen.
          </p>
        </section>
        <p className="rounded-2xl border border-amber-400/30 bg-amber-400/10 p-4 text-amber-200">
          Hinweis: Die mit [ ] markierten Felder bitte vor dem Livegang mit den echten
          Unternehmensdaten ersetzen.
        </p>
      </div>
    </main>
  );
}
