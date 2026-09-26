import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "GanzJahr | Garten- & Objektpflege · Winterdienst",
  description:
    "GanzJahr Garten & Objektpflege: Gartenpflege, Objektpflege und Winterdienst aus einer Hand. Zuverlässig. Sauber. Festpreis.",
  keywords: [
    "Gartenpflege",
    "Objektpflege",
    "Winterdienst",
    "Hausmeisterservice",
    "Grünpflege",
    "Festpreis",
  ],
  openGraph: {
    title: "GanzJahr | Garten- & Objektpflege · Winterdienst",
    description:
      "Ein Partner für 365 Tage: Gartenpflege, Objektpflege und Winterdienst zum Festpreis.",
    type: "website",
    locale: "de_DE",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="de">
      <body className={`${outfit.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
