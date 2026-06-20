import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Zaxo — Social Messenger",
  description:
    "Zaxo is a modern social messenger with a unique permanent Zaxo number, neumorphic UI, real-time chats, calls, and stories.",
  keywords: [
    "Zaxo",
    "messenger",
    "chat",
    "calls",
    "social",
    "neumorphism",
    "soft UI",
  ],
  authors: [{ name: "Zaxo" }],
  icons: {
    icon: "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='%236C5CE7'/><stop offset='1' stop-color='%23A29BFE'/></linearGradient></defs><rect width='100' height='100' rx='28' fill='url(%23g)'/><text x='50' y='68' font-size='52' font-family='Arial' font-weight='bold' fill='white' text-anchor='middle'>Z</text></svg>",
  },
  openGraph: {
    title: "Zaxo — Social Messenger",
    description:
      "Connect with anyone via your permanent Zaxo number. Neumorphic soft-UI social messenger.",
    siteName: "Zaxo",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#E0E5EC",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{var t=localStorage.getItem('zaxo-theme');if(!t){t=window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}if(t==='dark'){document.documentElement.classList.add('dark');}}catch(e){}})();`,
          }}
        />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        style={{ background: "var(--neu-bg)", color: "var(--neu-text)" }}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
