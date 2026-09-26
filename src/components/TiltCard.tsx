"use client";

import { useRef, useState, type ReactNode } from "react";

/** Card with real 3D perspective tilt + glare that follows the cursor. */
export default function TiltCard({
  children,
  className = "",
  max = 10,
}: {
  children: ReactNode;
  className?: string;
  max?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [style, setStyle] = useState<{ rx: number; ry: number; mx: number; my: number; on: boolean }>({
    rx: 0,
    ry: 0,
    mx: 50,
    my: 50,
    on: false,
  });

  return (
    <div
      ref={ref}
      onMouseMove={(e) => {
        const r = ref.current?.getBoundingClientRect();
        if (!r) return;
        const px = (e.clientX - r.left) / r.width;
        const py = (e.clientY - r.top) / r.height;
        setStyle({
          rx: (0.5 - py) * max * 2,
          ry: (px - 0.5) * max * 2,
          mx: px * 100,
          my: py * 100,
          on: true,
        });
      }}
      onMouseLeave={() => setStyle((s) => ({ ...s, rx: 0, ry: 0, on: false }))}
      style={{ perspective: "1100px" }}
      className={className}
    >
      <div
        className="relative h-full rounded-3xl transition-transform duration-200 ease-out will-change-transform"
        style={{
          transform: `rotateX(${style.rx}deg) rotateY(${style.ry}deg) translateZ(0) scale(${
            style.on ? 1.015 : 1
          })`,
          transformStyle: "preserve-3d",
        }}
      >
        {children}
        <div
          className="pointer-events-none absolute inset-0 rounded-3xl opacity-0 transition-opacity duration-300"
          style={{
            opacity: style.on ? 1 : 0,
            background: `radial-gradient(420px circle at ${style.mx}% ${style.my}%, rgba(134,204,65,0.16), transparent 60%)`,
          }}
        />
      </div>
    </div>
  );
}
