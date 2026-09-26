import Link from "next/link";
import type { Metadata } from "next";
import { site } from "@/lib/site";

export const metadata: Metadata = { title: "Datenschutz | GanzJahr" };

export default function Datenschutz() {
  return (
    <main className="mx-auto max-w-3xl px-4 py-28">
      <Link href="/" className="text-sm text-leaf-400 hover:underline">
        ← Zurück zur Startseite
      </Link>
      <h1 className="mt-6 text-4xl font-extrabold tracking-tight">Datenschutzerklärung</h1>
      <div className="mt-8 space-y-6 text-sm leading-relaxed text-white/70">
        <section>
          <h2 className="text-lg font-bold text-white">1. Verantwortlicher</h2>
          <p className="mt-2">
            {site.name} {site.tagline}, [Anschrift], E-Mail: {site.email}
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">2. Keine Cookies, kein Tracking</h2>
          <p className="mt-2">
            Diese Website setzt keine Analyse- oder Marketing-Cookies. Es findet keine
            Profilbildung statt.
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">3. Kontaktformular</h2>
          <p className="mt-2">
            Das Formular speichert keine Daten auf unserem Server: Es öffnet dein lokales
            E-Mail-Programm mit den eingegebenen Angaben. Die Verarbeitung deiner Anfrage erfolgt
            auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO.
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">4. Winter-Radar (Open-Meteo)</h2>
          <p className="mt-2">
            Für die Wetterampel wird beim Seitenaufruf eine Anfrage an api.open-meteo.com
            gesendet. Dabei wird technisch bedingt deine IP-Adresse an Open-Meteo übermittelt.
            Es werden ausschließlich die Koordinaten unseres Einsatzgebiets abgefragt, nicht dein
            Standort. Rechtsgrundlage: berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO).
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">5. Hosting</h2>
          <p className="mt-2">
            Die Website wird bei Vercel gehostet. Beim Aufruf werden Server-Logfiles (IP-Adresse,
            Zeitpunkt, User-Agent) verarbeitet, um den Betrieb sicherzustellen.
          </p>
        </section>
        <section>
          <h2 className="text-lg font-bold text-white">6. Deine Rechte</h2>
          <p className="mt-2">
            Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch
            nach Art. 15–21 DSGVO sowie Beschwerderecht bei einer Aufsichtsbehörde.
          </p>
        </section>
        <p className="rounded-2xl border border-amber-400/30 bg-amber-400/10 p-4 text-amber-200">
          Hinweis: Dieser Text ist eine Vorlage und ersetzt keine Rechtsberatung. Bitte vor dem
          Livegang prüfen lassen.
        </p>
      </div>
    </main>
  );
}
