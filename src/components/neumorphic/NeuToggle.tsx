// ==================== NEUMORPHIC TOGGLE ====================
"use client";

import { cn } from "@/lib/utils";

interface NeuToggleProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  description?: string;
  disabled?: boolean;
  size?: "sm" | "md";
}

export function NeuToggle({
  checked,
  onChange,
  label,
  description,
  disabled = false,
  size = "md",
}: NeuToggleProps) {
  const trackSize = size === "sm" ? 40 : 52;
  const thumbSize = size === "sm" ? 28 : 36;
  const offset = (trackSize - thumbSize) / 2;

  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => !disabled && onChange(!checked)}
      className={cn(
        "relative shrink-0 transition-all duration-300 focus-ring",
        checked ? "neu-accent" : "neu-well",
        disabled && "opacity-50 pointer-events-none",
      )}
      style={{
        width: trackSize,
        height: trackSize * 0.6,
        borderRadius: 999,
      }}
    >
      <span
        className="absolute top-1/2 -translate-y-1/2 transition-all duration-300"
        style={{
          width: thumbSize,
          height: thumbSize,
          left: checked ? trackSize - thumbSize - offset : offset,
          borderRadius: "50%",
          background: "var(--neu-surface)",
          boxShadow: checked
            ? "inset 1px 1px 2px rgba(0,0,0,0.15), 0 1px 2px rgba(255,255,255,0.4)"
            : "3px 3px 6px var(--neu-shadow-dark), -3px -3px 6px var(--neu-shadow-light)",
        }}
      />
    </button>
  );
}

interface NeuSettingRowProps {
  icon?: React.ReactNode;
  iconBg?: string;
  label: string;
  description?: string;
  right?: React.ReactNode;
  onClick?: () => void;
  danger?: boolean;
  showChevron?: boolean;
}

export function NeuSettingRow({
  icon,
  iconBg,
  label,
  description,
  right,
  onClick,
  danger = false,
  showChevron = false,
}: NeuSettingRowProps) {
  const Tag = onClick ? "button" : "div";
  return (
    <Tag
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-3 px-4 py-3.5 text-left transition-all",
        onClick && "hover:bg-[color:var(--neu-shadow-light)]/5 active:scale-[0.99]",
      )}
    >
      {icon && (
        <div
          className="shrink-0 flex items-center justify-center text-white"
          style={{
            width: 36,
            height: 36,
            borderRadius: 10,
            background: iconBg || "var(--neu-accent)",
          }}
        >
          {icon}
        </div>
      )}
      <div className="flex-1 min-w-0">
        <div
          className={cn(
            "text-sm font-medium truncate",
            danger ? "neu-text-danger" : "neu-text",
          )}
        >
          {label}
        </div>
        {description && (
          <div className="text-xs neu-text-muted truncate mt-0.5">{description}</div>
        )}
      </div>
      {right}
      {showChevron && (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="neu-text-muted shrink-0">
          <path
            d="M9 6l6 6-6 6"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      )}
    </Tag>
  );
}
