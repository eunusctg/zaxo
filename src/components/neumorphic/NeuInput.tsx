// ==================== NEUMORPHIC INPUT ====================
"use client";

import { cn } from "@/lib/utils";
import type { InputHTMLAttributes, TextareaHTMLAttributes, ReactNode } from "react";
import { useState } from "react";
import { Eye, EyeOff, X } from "lucide-react";

interface NeuInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "size"> {
  variant?: "well" | "raised";
  rounded?: "md" | "lg" | "xl" | "full";
  icon?: ReactNode;
  iconRight?: ReactNode;
  showClear?: boolean;
  onClear?: () => void;
  containerClassName?: string;
}

const roundedMap = {
  md: "rounded-xl",
  lg: "rounded-2xl",
  xl: "rounded-3xl",
  full: "rounded-full",
};

export function NeuInput({
  variant = "well",
  rounded = "lg",
  icon,
  iconRight,
  showClear = false,
  onClear,
  className,
  containerClassName,
  type = "text",
  value,
  ...props
}: NeuInputProps) {
  const [showPassword, setShowPassword] = useState(false);
  const isPassword = type === "password";
  const inputType = isPassword ? (showPassword ? "text" : "password") : type;

  return (
    <div
      className={cn(
        "flex items-center gap-2 px-4 py-3 transition-all",
        variant === "well" ? "neu-well" : "neu-raised-sm",
        roundedMap[rounded],
        containerClassName,
      )}
    >
      {icon && <span className="neu-text-muted shrink-0">{icon}</span>}
      <input
        type={inputType}
        value={value}
        className={cn(
          "flex-1 bg-transparent outline-none border-none neu-text placeholder:text-[color:var(--neu-text-muted)] text-sm min-w-0",
          className,
        )}
        {...props}
      />
      {isPassword && (
        <button
          type="button"
          onClick={() => setShowPassword((s) => !s)}
          className="neu-text-muted hover:neu-text-accent transition-colors shrink-0"
          tabIndex={-1}
        >
          {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
        </button>
      )}
      {showClear && value && (
        <button
          type="button"
          onClick={onClear}
          className="neu-text-muted hover:neu-text-accent transition-colors shrink-0"
          tabIndex={-1}
        >
          <X size={16} />
        </button>
      )}
      {iconRight && <span className="neu-text-muted shrink-0">{iconRight}</span>}
    </div>
  );
}

interface NeuTextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  variant?: "well" | "raised";
  rounded?: "md" | "lg" | "xl";
}

export function NeuTextarea({
  variant = "well",
  rounded = "lg",
  className,
  ...props
}: NeuTextareaProps) {
  return (
    <textarea
      className={cn(
        "px-4 py-3 outline-none border-none neu-text placeholder:text-[color:var(--neu-text-muted)] text-sm resize-none w-full transition-all",
        variant === "well" ? "neu-well" : "neu-raised-sm",
        roundedMap[rounded],
        className,
      )}
      {...props}
    />
  );
}
