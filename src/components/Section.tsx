"use client";

import { motion } from "framer-motion";
import type { ReactNode } from "react";

export default function Section({
  id,
  eyebrow,
  title,
  subtitle,
  children,
  className = "",
}: {
  id?: string;
  eyebrow?: string;
  title?: string;
  subtitle?: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section id={id} className={`relative scroll-mt-24 py-20 sm:py-28 ${className}`}>
      <div className="mx-auto max-w-7xl px-4">
        {(eyebrow || title) && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.5 }}
            className="mb-12 max-w-3xl"
          >
            {eyebrow && (
              <span className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-[0.22em] text-leaf-400">
                <span className="h-px w-8 bg-leaf-500" />
                {eyebrow}
              </span>
            )}
            {title && (
              <h2 className="mt-4 text-balance text-4xl font-extrabold leading-[1.05] tracking-tight sm:text-5xl">
                {title}
              </h2>
            )}
            {subtitle && (
              <p className="mt-4 text-pretty text-base leading-relaxed text-white/60 sm:text-lg">
                {subtitle}
              </p>
            )}
          </motion.div>
        )}
        {children}
      </div>
    </section>
  );
}
