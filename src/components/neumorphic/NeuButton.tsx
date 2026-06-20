// ==================== NEUMORPHIC BUTTON ====================
"use client";

import { cn } from "@/lib/utils";
import type { ButtonHTMLAttributes, ReactNode } from "react";

interface NeuButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "raised" | "inset" | "accent" | "danger" | "ghost";
  size?: "sm" | "md" | "lg";
  rounded?: "md" | "lg" | "xl" | "full";
  icon?: ReactNode;
  iconRight?: ReactNode;
  loading?: boolean;
  fullWidth?: boolean;
  children?: ReactNode;
}

const sizeMap = {
  sm: "px-3 py-2 text-xs gap-1.5",
  md: "px-4 py-2.5 text-sm gap-2",
  lg: "px-6 py-3.5 text-base gap-2.5",
};

const roundedMap = {
  md: "rounded-xl",
  lg: "rounded-2xl",
  xl: "rounded-3xl",
  full: "rounded-full",
};

const variantMap = {
  raised: "neu-pressable neu-text",
  inset: "neu-inset neu-text",
  accent: "neu-accent",
  danger: "neu-danger",
  ghost: "neu-text hover:opacity-70",
};

export function NeuButton({
  variant = "raised",
  size = "md",
  rounded = "lg",
  icon,
  iconRight,
  loading = false,
  fullWidth = false,
  children,
  className,
  disabled,
  ...props
}: NeuButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center font-medium transition-all focus-ring select-none",
        sizeMap[size],
        roundedMap[rounded],
        variantMap[variant],
        fullWidth && "w-full",
        (disabled || loading) && "opacity-50 pointer-events-none",
        className,
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <span
          className="inline-block rounded-full border-2 border-current border-t-transparent animate-spin"
          style={{ width: 14, height: 14 }}
        />
      ) : (
        icon
      )}
      {children && <span>{children}</span>}
      {iconRight}
    </button>
  );
}
