"use client";

/**
 * LayoutGrid — bento grid with an expand-on-click interaction, built for a
 * future Next.js migration of Talawin Marha's "أقسامنا / Our Divisions"
 * section.
 *
 * ⚠️ NOTE ON PROVENANCE: the request that asked for this file said to save
 * "the original React component" and left a placeholder for its pasted
 * source — but no code actually arrived in that placeholder. Nothing to
 * copy from was available in this session. What follows is a from-scratch
 * React + TypeScript + Tailwind + Framer Motion re-implementation that
 * reproduces, behaviourally, the exact interaction already shipped in
 * vanilla JS on companies/talawin-marha.html (#divisions section): a
 * 3-card bento grid where clicking a card expands it — via a FLIP
 * animation (Framer Motion's shared `layoutId`) — into a centered modal
 * panel over a dark overlay, with the description fading up afterwards.
 * If the real original component turns up, swap it in; treat this as a
 * faithful placeholder, not a byte-for-byte port.
 *
 * Not wired into the live site — the site is static HTML/CSS/vanilla JS.
 * This file only exists for whenever the project migrates to Next.js.
 *
 * Dependencies: react, framer-motion, tailwindcss.
 */

import { useEffect, useId, useState, type ReactNode } from "react";
import { AnimatePresence, motion } from "framer-motion";

export type LayoutGridCard = {
  id: string;
  /** lg = spans 2 cols, sm = 1 col, wide = spans all 3 cols (own row) */
  size: "lg" | "sm" | "wide";
  title: { en: string; ar: string };
  description: { en: string; ar: string };
  image: { src: string; alt: { en: string; ar: string } };
};

type Lang = "en" | "ar";

interface LayoutGridProps {
  cards: LayoutGridCard[];
  lang?: Lang;
}

const sizeClass: Record<LayoutGridCard["size"], string> = {
  lg: "md:col-span-2 md:row-start-1",
  sm: "md:col-span-1 md:row-start-1",
  wide: "md:col-span-3 md:row-start-2",
};

const EASE = [0.4, 0, 0.2, 1] as const; // matches --ease used on the live site

export function LayoutGrid({ cards, lang = "en" }: LayoutGridProps) {
  const [activeId, setActiveId] = useState<string | null>(null);
  const active = cards.find((c) => c.id === activeId) ?? null;
  const headingId = useId();

  // lock body scroll while a card is expanded (same as the vanilla-JS version)
  useEffect(() => {
    if (!active) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [active]);

  return (
    <div dir={lang === "ar" ? "rtl" : "ltr"}>
      <div className="relative mx-auto grid max-w-[1100px] grid-cols-1 gap-4 md:grid-cols-3 md:[grid-template-rows:320px_230px]">
        {cards.map((card) => (
          <motion.div
            layoutId={`card-${card.id}`}
            key={card.id}
            onClick={() => setActiveId(card.id)}
            role="button"
            tabIndex={0}
            aria-expanded={activeId === card.id}
            aria-label={`${card.title.en} / ${card.title.ar}`}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                setActiveId(card.id);
              }
            }}
            className={`group relative h-[250px] cursor-pointer overflow-hidden rounded-2xl outline-none focus-visible:ring-2 focus-visible:ring-amber-400 focus-visible:ring-offset-2 md:h-auto ${sizeClass[card.size]}`}
          >
            <motion.img
              layoutId={`image-${card.id}`}
              src={card.image.src}
              alt={`${card.image.alt.en} — ${card.image.alt.ar}`}
              loading="lazy"
              decoding="async"
              className="absolute inset-0 h-full w-full object-cover transition-transform duration-500 ease-out group-hover:scale-105"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent transition-opacity duration-300 group-hover:from-black/92 group-hover:via-black/45" />
            <div className="absolute inset-x-0 bottom-0 p-5">
              <span className="block text-lg font-extrabold text-white drop-shadow-sm">
                {lang === "ar" ? card.title.ar : card.title.en}
              </span>
            </div>
          </motion.div>
        ))}
      </div>

      <AnimatePresence>
        {active && (
          <>
            <motion.div
              key="overlay"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.3, ease: EASE }}
              className="fixed inset-0 z-[200] bg-black/30"
              onClick={() => setActiveId(null)}
              aria-hidden="true"
            />
            <EscToClose onEscape={() => setActiveId(null)}>
              <motion.div
                layoutId={`card-${active.id}`}
                role="dialog"
                aria-modal="true"
                aria-labelledby={headingId}
                transition={{ duration: 0.3, ease: EASE }}
                className="fixed left-1/2 top-1/2 z-[201] h-[70vh] w-[90vw] -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-2xl shadow-2xl md:h-1/2 md:w-1/2"
              >
                <motion.img
                  layoutId={`image-${active.id}`}
                  src={active.image.src}
                  alt={`${active.image.alt.en} — ${active.image.alt.ar}`}
                  className="absolute inset-0 h-full w-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/92 via-black/55 to-black/10" />
                <motion.div
                  initial={{ opacity: 0, y: 14 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.35, delay: 0.1, ease: EASE }}
                  className="absolute inset-x-0 bottom-0 p-6 md:p-10"
                >
                  <h3 id={headingId} className="mb-2 text-2xl font-extrabold text-white drop-shadow md:text-3xl">
                    {lang === "ar" ? active.title.ar : active.title.en}
                  </h3>
                  <p className="max-w-prose leading-relaxed text-white/90">
                    {lang === "ar" ? active.description.ar : active.description.en}
                  </p>
                </motion.div>
                <button
                  type="button"
                  onClick={() => setActiveId(null)}
                  aria-label={lang === "ar" ? "إغلاق" : "Close"}
                  className="absolute end-4 top-4 grid h-9 w-9 place-items-center rounded-full border border-white/25 bg-black/35 text-white transition-colors hover:bg-black/60"
                >
                  <CloseIcon />
                </button>
              </motion.div>
            </EscToClose>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}

/** Minimal Esc-to-close handler — swap for your design system's own focus trap if you have one. */
function EscToClose({ children, onEscape }: { children: ReactNode; onEscape: () => void }) {
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onEscape();
    }
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onEscape]);
  return <>{children}</>;
}

function CloseIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" aria-hidden="true">
      <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

/* -----------------------------------------------------------------------
   Example data — mirrors #tm-divisions-content in talawin-marha.html.
   In the Next.js migration this would come from a CMS/props instead.
   ----------------------------------------------------------------------- */
export const talawinDivisionCards: LayoutGridCard[] = [
  {
    id: "print",
    size: "lg",
    title: { en: "Advertising & Print", ar: "مطبوعات الدعاية والإعلان" },
    description: {
      en: "Design and execution of every kind of promotional print — brochures, booklets and company profiles, branded giveaways, and visual-identity materials — with high print quality and on-time delivery.",
      ar: "تصميم وتنفيذ المطبوعات الدعائية بجميع أنواعها: البروشورات والكتيبات والملفات التعريفية، والهدايا الدعائية، ومواد الهوية البصرية، بجودة طباعة عالية وتسليم في الموعد.",
    },
    image: {
      src: "https://images.unsplash.com/photo-1503694978374-8a2fa686963a?q=75&w=1600&auto=format&fit=crop",
      alt: { en: "Colour print run coming off a printing press", ar: "مطبوعات ملونة تخرج من مكبس الطباعة" },
    },
  },
  {
    id: "events",
    size: "sm",
    title: { en: "Events & Conferences", ar: "الفعاليات والمؤتمرات" },
    description: {
      en: "Organising and running events, conferences and exhibitions — from design and setup to booths, stages and décor — with full on-the-day execution management.",
      ar: "تنظيم وتنفيذ الفعاليات والمؤتمرات والمعارض، من التصميم والتجهيز إلى الأجنحة والمنصات والديكورات، مع إدارة كاملة لليوم التنفيذي.",
    },
    image: {
      src: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=75&w=1400&auto=format&fit=crop",
      alt: { en: "Conference hall with a speaker presenting to an audience", ar: "قاعة مؤتمرات مع متحدث أمام الحضور" },
    },
  },
  {
    id: "outdoor",
    size: "wide",
    title: { en: "Outdoor Advertising", ar: "اللوحات والإعلانات الخارجية" },
    description: {
      en: "Execution of outdoor billboards, illuminated signs, shop fronts and road signage, including obtaining the necessary permits, installation and maintenance.",
      ar: "تنفيذ اللوحات الإعلانية الخارجية واللوحات المضيئة وواجهات المحلات ولوحات الطرق، مع استخراج التصاريح اللازمة والتركيب والصيانة.",
    },
    image: {
      src: "https://images.unsplash.com/photo-1533069027836-fa937181a8ce?q=75&w=1900&auto=format&fit=crop",
      alt: { en: "Blank outdoor billboard against a clear sky", ar: "لوحة إعلانية خارجية فارغة أمام سماء صافية" },
    },
  },
];

/* Usage:
   <LayoutGrid cards={talawinDivisionCards} lang="ar" />
*/
