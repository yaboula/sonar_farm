// ============================================================
// Farm Sonar — Shell TopBar.
// ============================================================
//
// Shared top bar for both Manager and Tablet shells. Heights are
// driven by `--fs-topbar-h-manager` (64px) and `--fs-topbar-h-tablet`
// (56px) per UI Playbook v2 §12.
//
// Slots:
//   - Brand (left).
//   - Mode badge (manager / field).
//   - Optional center node (mono clock, IBAN, etc.).
//   - Close action (right).
// ============================================================

import { X } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Icon } from '@/components/ui/Icon';
import { LimePulse } from '@/components/ui/LimePulse';
import { useI18n } from '@/i18n';
import type { NuiMode } from '@/types/nui';

interface ShellTopBarProps {
    mode: NuiMode;
    onClose: () => void;
    /**
     * Visual variant — driven by parent shell. Controls the height
     * via `--fs-topbar-h-*` tokens.
     */
    variant: 'manager' | 'field';
}

export function ShellTopBar({ mode, onClose, variant }: ShellTopBarProps): JSX.Element {
    const { t } = useI18n();
    const heightStyle =
        variant === 'manager'
            ? { height: 'var(--fs-topbar-h-manager)' }
            : { height: 'var(--fs-topbar-h-tablet)' };

    return (
        <header
            className="flex items-center justify-between gap-6 border-b border-fs-border bg-fs-nav px-6 text-fs-fg-inverse"
            style={heightStyle}
            role="banner"
        >
            <div className="flex items-center gap-3">
                <LimePulse size="md" label={t('shell.brand')} />
                <Heading level="h3" as="span" className="text-fs-fg-inverse">
                    {t('shell.brand')}
                </Heading>
                <span className="rounded-full border border-fs-fg-inverse/20 px-2 py-0.5">
                    <Body size="micro" className="text-fs-fg-inverse/80">
                        {t(`mode.${mode}`)}
                    </Body>
                </span>
            </div>

            <button
                type="button"
                onClick={onClose}
                aria-label={t('shell.close')}
                className="inline-flex h-10 w-10 items-center justify-center rounded-2xl text-fs-fg-inverse/80 transition-colors duration-[var(--duration-fs-fast)] hover:bg-fs-fg-inverse/10 hover:text-fs-fg-inverse"
            >
                <Icon as={X} size="md" aria-label={t('shell.close')} />
            </button>
        </header>
    );
}
