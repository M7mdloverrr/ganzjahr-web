"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { Menu, X, Phone } from "lucide-react";
import { nav, site } from "@/lib/site";

export default function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 ${
        scrolled ? "py-2" : "py-4"
      }`}
    >
      <div className="mx-auto max-w-7xl px-4">
        <div
          className={`flex items-center justify-between rounded-2xl px-4 py-2.5 transition-all duration-500 ${
            scrolled ? "glass shadow-2xl shadow-black/40" : "bg-transparent"
          }`}
        >
          <Link href="#top" className="flex items-center gap-3">
            <span className="grid size-11 place-items-center rounded-full bg-white/95 p-1 shadow-lg shadow-black/30">
              <Image
                src="/emblem.png"
                alt="GanzJahr Garten & Objektpflege"
                width={120}
                height={120}
                priority
                className="size-full object-contain"
              />
            </span>
            <span className="leading-tight">
              <span className="block text-lg font-extrabold tracking-tight">
                GANZ<span className="text-leaf-400">JAHR</span>
              </span>
              <span className="block text-[10px] font-semibold uppercase tracking-[0.18em] text-ink-400">
                Garten &amp; Objektpflege
              </span>
            </span>
          </Link>

          <nav className="hidden items-center gap-1 lg:flex">
            {nav.map((n) => (
              <a
                key={n.href}
                href={n.href}
                className="rounded-lg px-3 py-2 text-sm font-medium text-white/75 transition hover:bg-white/5 hover:text-white"
              >
                {n.label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-2">
            <a
              href={site.phoneHref}
              className="hidden items-center gap-2 rounded-xl border border-white/10 px-3 py-2 text-sm font-semibold text-white/85 transition hover:border-leaf-500/60 hover:text-white sm:flex"
            >
              <Phone className="size-4 text-leaf-400" />
              Anrufen
            </a>
            <a
              href="#rechner"
              className="hidden rounded-xl bg-leaf-500 px-4 py-2 text-sm font-bold text-ink-950 shadow-lg shadow-leaf-500/25 transition hover:bg-leaf-400 sm:block"
            >
              Festpreis in 60 Sek.
            </a>
            <button
              type="button"
              aria-label="Menü"
              onClick={() => setOpen((v) => !v)}
              className="rounded-xl border border-white/10 p-2 lg:hidden"
            >
              {open ? <X className="size-5" /> : <Menu className="size-5" />}
            </button>
          </div>
        </div>

        {open && (
          <div className="glass mt-2 rounded-2xl p-2 lg:hidden">
            {nav.map((n) => (
              <a
                key={n.href}
                href={n.href}
                onClick={() => setOpen(false)}
                className="block rounded-xl px-4 py-3 text-sm font-medium text-white/80 hover:bg-white/5"
              >
                {n.label}
              </a>
            ))}
            <a
              href="#kontakt"
              onClick={() => setOpen(false)}
              className="mt-1 block rounded-xl bg-leaf-500 px-4 py-3 text-center text-sm font-bold text-ink-950"
            >
              Kostenloses Angebot
            </a>
          </div>
        )}
      </div>
    </header>
  );
}
