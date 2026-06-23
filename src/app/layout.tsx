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
  applicationName: "Zaxo",
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
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-16.png", sizes: "16x16", type: "image/png" },
    ],
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
    shortcut: "/zaxo-app-icon.png",
  },
  manifest: "/manifest.json",
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
