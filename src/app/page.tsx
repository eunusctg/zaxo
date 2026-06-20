"use client";

import { ZaxoApp } from "@/components/zaxo/ZaxoApp";

export default function Home() {
  return (
    <div
      className="min-h-screen w-full flex items-center justify-center"
      style={{ background: "var(--neu-bg)" }}
    >
      <ZaxoApp />
    </div>
  );
}
