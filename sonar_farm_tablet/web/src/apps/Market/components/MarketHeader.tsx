import { RefreshCcw } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { Mono } from '@/components/typography/Mono';
import { Button, Card, LimePulse } from '@/components/ui';
import { useI18n } from '@/i18n';

import { formatPriceEurPerKg } from '../market.utils';
import type { MarketSignals } from '../types';

interface MarketHeaderProps {
    signals: MarketSignals;
    loading: boolean;
    onRefresh: () => void;
}

export function MarketHeader({ signals, loading, onRefresh }: MarketHeaderProps): JSX.Element {
    const { locale, t } = useI18n();

    const stats = [
        {
            key: 'online',
            label: t('market.header.stats.online'),
            value: String(signals.online),
            live: signals.online > 0,
        },
        {
            key: 'premium',
            label: t('market.header.stats.premium'),
            value: String(signals.premium),
            live: false,
        },
        {
            key: 'contracts',
            label: t('market.header.stats.contracts'),
            value: String(signals.contractsOpen),
            live: false,
        },
        {
            key: 'top-price',
            label: t('market.header.stats.top_price'),
            value: formatPriceEurPerKg(signals.topPriceEurPerKg, locale),
            live: false,
        },
    ] as const;

    return (
        <header className="flex flex-col gap-8 xl:flex-row xl:items-end xl:justify-between xl:gap-12">
            <div className="flex max-w-3xl flex-col gap-4">
                <div className="flex items-center gap-3 text-fs-fg-muted">
                    <Body size="micro" as="span">
                        {t('shell.brand')}
                    </Body>
                    <span className="h-px w-4 bg-fs-border" />
                    <Body size="micro" as="span">
                        {t('page.market.title')}
                    </Body>
                </div>

                <Heading level="display" as="h1" className="text-[clamp(3.5rem,8vw,7.5rem)] leading-[0.92] tracking-[-0.04em]">
                    {t('market.header.wordmark')}
                </Heading>

                <Body size="small" muted className="max-w-xl text-[0.875rem] leading-[1.6]">
                    {t('market.header.description')}
                </Body>
            </div>

            <div className="flex flex-col gap-4 self-start xl:min-w-[520px] xl:self-end">
                <Button
                    variant="secondary"
                    size="md"
                    onClick={onRefresh}
                    loading={loading}
                    leftIcon={<RefreshCcw size={16} strokeWidth={1.5} />}
                    className="self-start"
                >
                    {t('market.refresh')}
                </Button>

                <Card padding="compact" className="overflow-hidden p-0">
                    <div className="grid grid-cols-2 md:grid-cols-4">
                        {stats.map((stat, index) => (
                            <div
                                key={stat.key}
                                className={[
                                    'flex min-h-[104px] flex-col justify-between px-5 py-4',
                                    index > 0 ? 'border-l border-fs-border' : '',
                                ]
                                    .filter(Boolean)
                                    .join(' ')}
                            >
                                <div className="flex items-center gap-2">
                                    <Body size="micro" as="span" className="text-fs-fg-muted">
                                        {stat.label}
                                    </Body>
                                    {stat.live ? <LimePulse size="sm" label={t('market.pulse.live')} /> : null}
                                </div>
                                <Mono size="default" className="text-[1.875rem] font-medium tracking-[-0.03em]">
                                    {stat.value}
                                </Mono>
                            </div>
                        ))}
                    </div>
                </Card>
            </div>
        </header>
    );
}
