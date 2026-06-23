// ==================== ZAXO LOGO ====================
"use client";

interface ZaxoLogoProps {
  size?: number;
  animated?: boolean;
  showText?: boolean;
  useImage?: boolean; // when true, use generated PNG; otherwise SVG
}

export function ZaxoLogo({ size = 64, animated = false, showText = false, useImage = false }: ZaxoLogoProps) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div
        className={animated ? "neu-breathe rounded-3xl flex items-center justify-center overflow-hidden" : "neu-floating rounded-3xl flex items-center justify-center overflow-hidden"}
        style={{ width: size, height: size }}
      >
        {useImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src="/zaxo-app-icon.png"
            alt="Zaxo"
            width={size}
            height={size}
            style={{ objectFit: "cover", width: "100%", height: "100%" }}
          />
        ) : (
          <svg
            width={size * 0.6}
            height={size * 0.6}
            viewBox="0 0 100 100"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <defs>
              <linearGradient id="zaxo-grad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor="#6C5CE7" />
                <stop offset="1" stopColor="#A29BFE" />
              </linearGradient>
            </defs>
            <path
              d="M28 22 L72 22 L72 32 L42 72 L72 72 L72 82 L26 82 L26 72 L56 32 L28 32 Z"
              fill="url(#zaxo-grad)"
            />
            <circle cx="50" cy="50" r="46" stroke="url(#zaxo-grad)" strokeWidth="2" strokeDasharray="4 6" opacity="0.25" />
          </svg>
        )}
      </div>
      {showText && (
        <div className="text-center">
          <div
            className="font-bold tracking-tight neu-text"
            style={{ fontSize: size * 0.4 }}
          >
            Zaxo
          </div>
          <div className="text-xs neu-text-muted mt-1">Connect by number</div>
        </div>
      )}
    </div>
  );
}
