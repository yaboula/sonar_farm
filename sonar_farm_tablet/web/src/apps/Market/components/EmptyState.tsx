import { Moon } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Mono } from '@/components/typography/Mono';
import { Icon } from '@/components/ui';
import { useI18n } from '@/i18n';

interface EmptyStateProps {
    nextOpenLabel: string;
    lastCloseLabel: string;
}

export function EmptyState({ nextOpenLabel, lastCloseLabel }: EmptyStateProps): JSX.Element {
    const { t } = useI18n();

    return (
        <div className="fs-slide-up flex flex-col items-center rounded-[20px] border border-fs-border bg-fs-surface px-8 py-16 text-center md:py-24" data-testid="market-empty">
            <div className="mb-7 flex h-12 w-12 items-center justify-center rounded-full border border-fs-border text-fs-fg-muted">
                <Icon as={Moon} size="lg" />
            </div>

            <Heading level="h1" as="h2" className="text-[1.75rem] tracking-[-0.02em] md:text-[2.125rem]">
                {t('market.empty.title')}
            </Heading>

            <Body size="small" muted className="mt-3 max-w-[460px] text-[0.875rem] leading-[1.6]">
                {t('market.empty.body')}
            </Body>

            <div className="mt-8 flex flex-wrap items-center justify-center gap-3 text-[0.75rem]">
                <div className="flex items-center gap-2 rounded-full border border-fs-border px-3 py-1.5">
                    <Body size="micro" as="span" className="text-fs-fg-muted">
                        {t('market.empty.reopens')}
                    </Body>
                    <Mono size="small">{nextOpenLabel}</Mono>
                </div>
                <div className="flex items-center gap-2 rounded-full border border-fs-border px-3 py-1.5">
                    <Body size="micro" as="span" className="text-fs-fg-muted">
                        {t('market.empty.last_close')}
                    </Body>
                    <Mono size="small">{lastCloseLabel}</Mono>
                </div>
            </div>

            <div className="mt-12 w-full max-w-[520px] border-t border-fs-border pt-6">
                <Body size="micro" as="span" className="text-fs-fg-muted">
                    {t('market.empty.tip')}
                </Body>
            </div>
        </div>
    );
}
