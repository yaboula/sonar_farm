import { ChevronRight, Radio } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Mono } from '@/components/typography/Mono';
import { LimePulse } from '@/components/ui';
import { useI18n } from '@/i18n';

import { deltaTone } from '../market.utils';
import type { MarketBuyerViewModel } from '../types';

interface PulseBarProps {
    buyers: ReadonlyArray<MarketBuyerViewModel>;
    day: number;
    snapshotLabel: string;
}

export function PulseBar({ buyers, day, snapshotLabel }: PulseBarProps): JSX.Element {
    const { t } = useI18n();
    const deltas = buyers.filter((buyer) => buyer.delta !== 'stable').slice(0, 4);

    return (
        <div className="flex min-h-[52px] w-full items-center gap-3 rounded-full bg-fs-nav px-3 py-2 text-fs-fg-inverse">
            <div className="flex items-center gap-2 border-r border-white/10 px-2 pr-3">
                <LimePulse size="sm" label={t('market.pulse.live')} />
                <Body size="micro" as="span" className="text-white/75">
                    {t('market.pulse.live')}
                </Body>
            </div>

            <div className="flex items-baseline gap-2 border-r border-white/10 pr-4">
                <Mono size="small" className="text-fs-fg-inverse">
                    {snapshotLabel}
                </Mono>
                <Body size="small" as="span" className="text-white/55">
                    {t(`market.seasons.${day > 0 ? 'day' : 'unknown'}`, { day })}
                </Body>
            </div>

            <div className="flex min-w-0 flex-1 items-center gap-2 overflow-hidden">
                <Radio size={14} strokeWidth={1.5} className="shrink-0 text-white/55" />
                <div className="flex min-w-0 items-center gap-1.5 overflow-hidden whitespace-nowrap">
                    {deltas.length === 0 ? (
                        <Body size="small" as="span" className="truncate text-white/55">
                            {t('market.pulse.no_movements')}
                        </Body>
                    ) : (
                        deltas.map((buyer, index) => {
                            const tone = deltaTone(buyer.delta);
                            const toneClass =
                                tone === 'accent'
                                    ? 'text-fs-accent'
                                    : tone === 'danger'
                                      ? 'text-[rgb(253_227_227)]'
                                      : 'text-white/60';

                            return (
                                <div key={buyer.id} className="flex min-w-0 items-center gap-1.5">
                                    {index > 0 ? <span className="text-[0.6875rem] text-white/20">·</span> : null}
                                    <Body size="small" as="span" className="truncate text-white/90">
                                        {t(buyer.nameKey)}
                                    </Body>
                                    <Body size="small" as="span" className={toneClass}>
                                        {t(`market.delta.${buyer.delta}`)}
                                    </Body>
                                </div>
                            );
                        })
                    )}
                </div>
            </div>

            <div className="inline-flex shrink-0 items-center gap-1.5 rounded-full bg-fs-accent px-3 py-1.5 text-fs-fg">
                <Body size="small" as="span" className="font-medium text-fs-fg">
                    {t('market.pulse.day', { day })}
                </Body>
                <ChevronRight size={14} strokeWidth={1.8} />
            </div>
        </div>
    );
}
