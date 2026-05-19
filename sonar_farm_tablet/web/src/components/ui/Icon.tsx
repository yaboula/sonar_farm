// ============================================================
// Farm Sonar — Icon wrapper.
// ============================================================
//
// Single entrypoint for Lucide React icons. Centralizes the
// stroke-width 1.5 rule (Playbook v2 §8.3) and the size scale
// (Playbook v2 §8.2). Components MUST go through this wrapper
// rather than importing Lucide icons directly.
// ============================================================

import type { LucideIcon } from 'lucide-react';

export type IconSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

const SIZE_PX: Record<IconSize, number> = {
    xs: 12,
    sm: 16,
    md: 20,
    lg: 24,
    xl: 32,
};

interface IconProps {
    as: LucideIcon;
    size?: IconSize;
    color?: string;
    className?: string;
    'aria-label'?: string;
    'aria-hidden'?: boolean;
}

export function Icon({
    as: Component,
    size = 'sm',
    color,
    className,
    'aria-label': ariaLabel,
    'aria-hidden': ariaHidden,
}: IconProps): JSX.Element {
    return (
        <Component
            size={SIZE_PX[size]}
            strokeWidth={1.5}
            color={color}
            className={className}
            aria-label={ariaLabel}
            aria-hidden={ariaHidden ?? (ariaLabel ? undefined : true)}
        />
    );
}
