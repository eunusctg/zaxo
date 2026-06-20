// ==================== NEUMORPHIC AVATAR ====================
"use client";

import { cn } from "@/lib/utils";

interface NeuAvatarProps {
  initial: string;
  gradient: string;
  size?: number;
  online?: boolean;
  ring?: "none" | "unviewed" | "viewed";
  className?: string;
}

export function NeuAvatar({
  initial,
  gradient,
  size = 48,
  online = false,
  ring = "none",
  className,
}: NeuAvatarProps) {
  const inner = (
    <div
      className={cn("relative flex items-center justify-center font-semibold text-white", className)}
      style={{
        width: "100%",
        height: "100%",
        background: gradient,
        borderRadius: "50%",
        fontSize: size * 0.42,
      }}
    >
      {initial}
    </div>
  );

  return (
    <div style={{ width: size, height: size, position: "relative" }}>
      {ring === "unviewed" ? (
        <div className="status-ring-unviewed" style={{ width: size, height: size }}>
          <div
            className="neu-surface flex items-center justify-center"
            style={{ width: size - 5, height: size - 5, borderRadius: "50%", padding: 2 }}
          >
            {inner}
          </div>
        </div>
      ) : ring === "viewed" ? (
        <div className="status-ring-viewed" style={{ width: size, height: size }}>
          <div
            className="neu-surface flex items-center justify-center"
            style={{ width: size - 5, height: size - 5, borderRadius: "50%", padding: 2 }}
          >
            {inner}
          </div>
        </div>
      ) : (
        <div
          className="neu-raised-sm flex items-center justify-center"
          style={{ width: size, height: size, borderRadius: "50%", padding: 3 }}
        >
          {inner}
        </div>
      )}
      {online && (
        <div
          className="online-dot"
          style={{
            position: "absolute",
            bottom: 0,
            right: 0,
            width: size * 0.22,
            height: size * 0.22,
            borderRadius: "50%",
          }}
        />
      )}
    </div>
  );
}
