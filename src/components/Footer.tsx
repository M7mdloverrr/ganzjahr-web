import Image from "next/image";
import { nav, site } from "@/lib/site";

export default function Footer() {
  return (
    <footer className="border-t border-white/10 bg-ink-900/60">
      <div className="mx-auto grid max-w-7xl gap-10 px-4 py-14 sm:grid-cols-2 lg:grid-cols-4">
        <div className="sm:col-span-2">
          <div className="flex items-center gap-4">
            <span className="grid size-16 place-items-center rounded-full bg-white/95 p-1.5">
              <Image
                src="/emblem.png"
                alt="GanzJahr Garten & Objektpflege"
                width={160}
                height={160}
                className="size-full object-contain"
              />
            </span>
            <span className="leading-tight">
              <span className="block text-2xl font-extrabold tracking-tight">
                GANZ<span className="text-leaf-400">JAHR</span>
              </span>
              <span className="block text-[11px] font-semibold uppercase tracking-[0.18em] text-white/45">
                Garten &amp; Objektpflege
              </span>
            </span>
          </div>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-white/50">
            Gartenpflege, Objektpflege und Winterdienst aus einer Hand – {site.claim}
          </p>
        </div>
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/40">
            Navigation
          </p>
          <ul className="mt-4 space-y-2 text-sm">
            {nav.map((n) => (
              <li key={n.href}>
                <a href={n.href} className="text-white/60 transition hover:text-leaf-400">
                  {n.label}
                </a>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-white/40">Kontakt</p>
          <ul className="mt-4 space-y-2 text-sm text-white/60">
            <li>
              <a href={site.phoneHref} className="transition hover:text-leaf-400">
                {site.phone}
              </a>
            </li>
            <li>
              <a href={`mailto:${site.email}`} className="transition hover:text-leaf-400">
                {site.email}
              </a>
            </li>
            <li>
              {site.city} · Umkreis {site.serviceRadiusKm} km
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/10">
        <div className="mx-auto flex max-w-7xl flex-col gap-2 px-4 py-6 text-xs text-white/35 sm:flex-row sm:items-center sm:justify-between">
          <p>
            © {new Date().getFullYear()} {site.name} {site.tagline}. Alle Rechte vorbehalten.
          </p>
          <p className="flex gap-4">
            <a href="/impressum" className="hover:text-white/60">
              Impressum
            </a>
            <a href="/datenschutz" className="hover:text-white/60">
              Datenschutz
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}
