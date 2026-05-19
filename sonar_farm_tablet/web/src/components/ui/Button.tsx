// ============================================================
// Farm Sonar — Button primitive.
// ============================================================
//
// shadcn-compatible local primitive per UI Playbook v2 §10.6.
// Variants:
//   primary      — lime accent fill (single CTA per screen).
//   secondary    — outline on white surface.
//   ghost        — text-only.
//   destructive  — danger fg on danger bg.
//
// Sizes h-32/40/48 (sm/md/lg). Focus ring inherits the global
// `:focus-visible` rule from globals.css.
// ============================================================

import type { ButtonHTMLAttributes, ReactNode } from 'react';

import { LoaderCircle } from 'lucide-react';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'destructive';
export type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: ButtonVariant;
    size?: ButtonSize;
    leftIcon?: ReactNode;
    rightIcon?: ReactNode;
    loading?: boolean;
    children?: ReactNode;
}

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
    primary:
        'bg-fs-accent text-fs-fg hover:bg-fs-accent-hover active:bg-fs-accent-hover border border-transparent',
    secondary:
        'bg-fs-surface text-fs-fg border border-fs-border hover:bg-[rgb(150_156_156_/_0.08)]',
    ghost: 'bg-transparent text-fs-fg hover:bg-[rgb(150_156_156_/_0.08)] border border-transparent',
    destructive: 'bg-fs-danger-bg text-fs-danger-fg border border-transparent hover:brightness-95',
};

const SIZE_CLASSES: Record<ButtonSize, string> = {
    sm: 'h-8 px-3 text-[0.875rem]',
    md: 'h-10 px-4 text-[1rem]',
    lg: 'h-12 px-5 text-[1rem]',
};

export function Button({
    variant = 'primary',
    size = 'md',
    leftIcon,
    rightIcon,
    loading = false,
    disabled,
    className,
    children,
    ...rest
}: ButtonProps): JSX.Element {
    const cls = [
        'inline-flex items-center justify-center gap-2 rounded-2xl font-medium',
        'transition-colors duration-[var(--duration-fs-fast)] ease-[var(--ease-out-fs)]',
        'disabled:cursor-not-allowed disabled:opacity-50',
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        className,
    ]
        .filter(Boolean)
        .join(' ');

    const isInactive = disabled || loading;

    return (
        <button className={cls} disabled={isInactive} {...rest}>
            {loading ? (
                <LoaderCircle size={16} strokeWidth={1.5} className="animate-spin" />
            ) : (
                leftIcon
            )}
            {children}
            {!loading && rightIcon}
        </button>
    );
}
