// ============================================================
// Farm Sonar — Body primitive.
// ============================================================
//
// Body / small / micro typography per UI Playbook v2 §4.2.
// Default tone uses `text-fs-fg`; pass `muted` for the secondary
// color `text-fs-fg-muted`.
// ============================================================

import type { HTMLAttributes, ReactNode } from 'react';

export type BodySize = 'default' | 'small' | 'micro';

interface BodyProps extends Omit<HTMLAttributes<HTMLParagraphElement>, 'children'> {
    size?: BodySize;
    muted?: boolean;
    as?: 'p' | 'span' | 'div';
    children: ReactNode;
}

const SIZE_CLASSES: Record<BodySize, string> = {
    default: 'text-[1rem] leading-[1.55] font-normal',
    small: 'text-[0.875rem] leading-[1.45] font-normal',
    micro: 'text-[0.75rem] leading-[1.4] font-medium tracking-[0.01em] uppercase',
};

export function Body({
    size = 'default',
    muted = false,
    as = 'p',
    className,
    children,
    ...rest
}: BodyProps): JSX.Element {
    const Tag = as;
    const cls = [SIZE_CLASSES[size], muted ? 'text-fs-fg-muted' : 'text-fs-fg', className]
        .filter(Boolean)
        .join(' ');
    return (
        <Tag className={cls} {...rest}>
            {children}
        </Tag>
    );
}
