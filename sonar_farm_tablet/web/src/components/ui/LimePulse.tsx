// ============================================================
// Farm Sonar — LimePulse signature component.
// ============================================================
//
// Calm-Tech lime dot used to signal liveness, readiness or
// attention required. Implemented with the `.fs-pulse` CSS
// keyframes from globals.css, so `prefers-reduced-motion` is
// respected automatically.
//
// Spec: UI Playbook v2 §10.4.
// ============================================================

export type LimePulseSize = 'sm' | 'md' | 'lg';

const SIZE_CLASS: Record<LimePulseSize, string> = {
    sm: 'h-2 w-2',
    md: 'h-3 w-3',
    lg: 'h-4 w-4',
};

interface LimePulseProps {
    size?: LimePulseSize;
    label?: string;
    className?: string;
}

export function LimePulse({ size = 'md', label, className }: LimePulseProps): JSX.Element {
    const cls = [
        'fs-pulse inline-block rounded-full bg-fs-accent shadow-[var(--shadow-fs-glow)]',
        SIZE_CLASS[size],
        className,
    ]
        .filter(Boolean)
        .join(' ');

    return (
        <span
            className={cls}
            role={label ? 'status' : undefined}
            aria-label={label}
            aria-hidden={label ? undefined : true}
        />
    );
}
