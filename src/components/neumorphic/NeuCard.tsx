// ==================== NEUMORPHIC CARD ====================
"use client";

import { cn } from "@/lib/utils";
import type { HTMLAttributes, ReactNode } from "react";

interface NeuCardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: "raised" | "raised-sm" | "raised-lg" | "inset" | "floating";
  rounded?: "md" | "lg" | "xl" | "2xl" | "3xl";
  padding?: "none" | "sm" | "md" | "lg" | "xl";
  children: ReactNode;
}

const roundedMap = {
  md: "rounded-xl",
  lg: "rounded-2xl",
  xl: "rounded-3xl",
  "2xl": "rounded-[1.5rem]",
  "3xl": "rounded-[2rem]",
};

const paddingMap = {
  none: "p-0",
  sm: "p-3",
  md: "p-4",
  lg: "p-6",
  xl: "p-8",
};

const variantMap = {
  raised: "neu-raised",
  "raised-sm": "neu-raised-sm",
  "raised-lg": "neu-raised-lg",
  inset: "neu-inset",
  floating: "neu-floating",
};

export function NeuCard({
  variant = "raised",
  rounded = "xl",
  padding = "md",
  className,
  children,
  ...props
}: NeuCardProps) {
  return (
    <div
      className={cn(
        variantMap[variant],
        roundedMap[rounded],
        paddingMap[padding],
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}
