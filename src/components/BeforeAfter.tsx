"use client";

import { useRef, useState } from "react";
import { MoveHorizontal } from "lucide-react";
import Section from "@/components/Section";

/** Stylised courtyard illustration – "after" adds mown stripes, trimmed hedge and clean paving. */
function Scene({ after }: { after: boolean }) {
  const grass = after ? "#4d9520" : "#6b6a3a";
  const grassDark = after ? "#3c7719" : "#57562f";
  const hedge = after ? "#3c7719" : "#5b6438";
  const paving = after ? "#b9c4cc" : "#8c8b7e";
  const sky1 = after ? "#1d2a36" : "#252a2c";

  return (
    <svg viewBox="0 0 800 500" className="h-full w-full" preserveAspectRatio="xMidYMid slice">
      <defs>
        <linearGradient id={`sky-${after}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={sky1} />
          <stop offset="100%" stopColor="#10171e" />
        </linearGradient>
      </defs>
      <rect width="800" height="500" fill={`url(#sky-${after})`} />

      {/* building */}
      <rect x="470" y="90" width="230" height="250" rx="6" fill="#263542" />
      <rect x="418" y="170" width="70" height="170" rx="5" fill="#2f4150" />
      {Array.from({ length: 12 }).map((_, i) => (
        <rect
          key={i}
          x={500 + (i % 4) * 50}
          y={120 + Math.floor(i / 4) * 60}
          width="30"
          height="40"
          rx="3"
          fill={after ? "#ffd489" : "#3a4a58"}
          opacity={after ? 0.85 : 1}
        />
      ))}

      {/* ground */}
      <rect x="0" y="330" width="800" height="170" fill={grassDark} />
      <path d="M0 330 Q 400 300 800 336 L800 500 L0 500Z" fill={grass} />

      {/* mown stripes */}
      {after &&
        Array.from({ length: 7 }).map((_, i) => (
          <path
            key={i}
            d={`M${-60 + i * 130} 500 L${20 + i * 130} 340 L${80 + i * 130} 340 L${20 + i * 130} 500Z`}
            fill="#63b32a"
            opacity="0.35"
          />
        ))}

      {/* weeds when before */}
      {!after &&
        Array.from({ length: 34 }).map((_, i) => {
          const x = 20 + ((i * 97) % 760);
          const y = 350 + ((i * 53) % 130);
          return (
            <path
              key={i}
              d={`M${x} ${y} q4 -18 10 -26 q-2 16 2 26Z`}
              fill="#8a9046"
              opacity="0.9"
            />
          );
        })}

      {/* hedge */}
      <rect x="40" y={after ? 288 : 268} width="330" height={after ? 52 : 72} rx={after ? 8 : 26} fill={hedge} />
      {!after &&
        Array.from({ length: 16 }).map((_, i) => (
          <circle key={i} cx={60 + i * 20} cy={262 + ((i * 37) % 24)} r={9} fill="#6c7540" />
        ))}

      {/* path */}
      <path d="M300 500 L360 340 L430 340 L410 500Z" fill={paving} opacity="0.9" />
      {after &&
        Array.from({ length: 5 }).map((_, i) => (
          <path
            key={i}
            d={`M${312 + i * 4} ${480 - i * 34} L${404 - i * 4} ${480 - i * 34}`}
            stroke="#e9f1f6"
            strokeWidth="2"
            opacity="0.25"
          />
        ))}

      {/* litter / leaves before */}
      {!after &&
        Array.from({ length: 22 }).map((_, i) => (
          <ellipse
            key={i}
            cx={60 + ((i * 131) % 700)}
            cy={360 + ((i * 71) % 120)}
            rx="9"
            ry="5"
            fill="#a8762f"
            opacity="0.75"
            transform={`rotate(${(i * 37) % 180} ${60 + ((i * 131) % 700)} ${360 + ((i * 71) % 120)})`}
          />
        ))}

      {/* tree */}
      <rect x="150" y="210" width="16" height="110" rx="6" fill="#5a4632" />
      <circle cx="158" cy="190" r="58" fill={after ? "#63b32a" : "#6d6f3b"} />
      <circle cx="118" cy="214" r="34" fill={after ? "#4d9520" : "#5f6335"} />
      <circle cx="198" cy="212" r="36" fill={after ? "#86cc41" : "#767a41"} />
    </svg>
  );
}

export default function BeforeAfter() {
  const [pos, setPos] = useState(48);
  const ref = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);

  const move = (clientX: number) => {
    const r = ref.current?.getBoundingClientRect();
    if (!r) return;
    setPos(Math.min(100, Math.max(0, ((clientX - r.left) / r.width) * 100)));
  };

  return (
    <Section
      eyebrow="Vorher / Nachher"
      title="Der Unterschied, den eine Tour macht."
      subtitle="Zieh den Regler. Links der typische Zustand vor Vertragsbeginn, rechts der Standard, den wir das ganze Jahr halten."
    >
      <div
        ref={ref}
        onMouseDown={(e) => {
          dragging.current = true;
          move(e.clientX);
        }}
        onMouseMove={(e) => dragging.current && move(e.clientX)}
        onMouseUp={() => (dragging.current = false)}
        onMouseLeave={() => (dragging.current = false)}
        onTouchStart={(e) => move(e.touches[0].clientX)}
        onTouchMove={(e) => move(e.touches[0].clientX)}
        className="relative aspect-[16/10] w-full cursor-ew-resize select-none overflow-hidden rounded-3xl border border-white/10 sm:aspect-[16/7]"
      >
        <div className="absolute inset-0">
          <Scene after />
        </div>
        <div className="absolute inset-0" style={{ clipPath: `inset(0 ${100 - pos}% 0 0)` }}>
          <Scene after={false} />
        </div>

        <span className="absolute left-4 top-4 rounded-full bg-ink-950/70 px-3 py-1 text-xs font-bold uppercase tracking-widest text-white/70 backdrop-blur">
          Vorher
        </span>
        <span className="absolute right-4 top-4 rounded-full bg-leaf-500 px-3 py-1 text-xs font-bold uppercase tracking-widest text-ink-950">
          GanzJahr
        </span>

        <div
          className="absolute inset-y-0 w-0.5 bg-white/90"
          style={{ left: `${pos}%` }}
        >
          <span className="absolute left-1/2 top-1/2 grid size-12 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full bg-white text-ink-950 shadow-2xl">
            <MoveHorizontal className="size-5" />
          </span>
        </div>
      </div>
      <p className="mt-4 text-center text-xs text-white/35">
        Illustration – echte Objektfotos folgen nach Freigabe der Eigentümer.
      </p>
    </Section>
  );
}
