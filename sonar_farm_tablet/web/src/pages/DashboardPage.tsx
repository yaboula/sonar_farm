// ============================================================
// Farm Sonar — DashboardPage (the only S4 page with demo data).
// ============================================================
//
// Implements the DashboardPage template per UI Playbook v2 §13.1.
// Demo data lives ONLY here, clearly marked as placeholder, so
// later slices (S5 plots, S7 batches, S22 reputation...) can
// replace it incrementally.
// ============================================================

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { BentoGrid } from '@/components/layout/BentoGrid';
import { BatchChip } from '@/components/ui/BatchChip';
import { Card } from '@/components/ui/Card';
import { LimePulse } from '@/components/ui/LimePulse';
import { useI18n } from '@/i18n';

interface KpiCardProps {
    label: string;
    value: string;
    accented?: boolean;
}

function KpiCard({ label, value, accented = false }: KpiCardProps): JSX.Element {
    return (
        <Card padding="comfortable">
            <Card.Body>
                <div className="flex items-center gap-2">
                    {accented ? <LimePulse size="sm" /> : null}
                    <Body size="micro" muted>
                        {label}
                    </Body>
                </div>
                <Heading level="display" as="span" className="text-fs-fg">
                    {value}
                </Heading>
            </Card.Body>
        </Card>
    );
}

export function DashboardPage(): JSX.Element {
    const { t } = useI18n();

    return (
        <section className="fs-fade-in flex flex-col gap-8">
            <header className="flex flex-col gap-1">
                <Body size="small" muted>
                    {t('page.dashboard.greeting')}
                </Body>
                <Heading level="h1" as="h1">
                    {t('page.dashboard.title')}
                </Heading>
                <Body size="small" muted>
                    {t('page.dashboard.subtitle')}
                </Body>
            </header>

            <BentoGrid gap="md" columns={12}>
                <BentoGrid.Item span={3}>
                    <KpiCard
                        label={t('demo.dashboard.harvestReady')}
                        value={t('demo.dashboard.harvestReadyValue')}
                        accented
                    />
                </BentoGrid.Item>
                <BentoGrid.Item span={3}>
                    <KpiCard
                        label={t('demo.dashboard.activeContracts')}
                        value={t('demo.dashboard.activeContractsValue')}
                    />
                </BentoGrid.Item>
                <BentoGrid.Item span={3}>
                    <KpiCard
                        label={t('demo.dashboard.freshBatches')}
                        value={t('demo.dashboard.freshBatchesValue')}
                    />
                </BentoGrid.Item>
                <BentoGrid.Item span={3}>
                    <KpiCard label={t('demo.dashboard.cashBalance')} value="€ 12 480" />
                </BentoGrid.Item>

                <BentoGrid.Item span={8}>
                    <Card padding="comfortable">
                        <Card.Header>
                            <Heading level="h2" as="h2">
                                {t('demo.dashboard.sampleBatchHint')}
                            </Heading>
                        </Card.Header>
                        <Card.Body>
                            <div className="flex flex-wrap items-center gap-2">
                                <BatchChip batchId="b_8f3a4e2c91d0" quality="A" freshness={87} />
                                <BatchChip batchId="b_2c7e91a40b13" quality="S" freshness={92} />
                                <BatchChip batchId="b_45ab12cd9032" quality="B" freshness={64} />
                                <BatchChip batchId="b_1f08fa70d2cd" quality="C" freshness={22} />
                            </div>
                            <Body size="small" muted>
                                {t('demo.dashboard.demoCallout')}
                            </Body>
                        </Card.Body>
                    </Card>
                </BentoGrid.Item>

                <BentoGrid.Item span={4}>
                    <Card padding="comfortable">
                        <Card.Body>
                            <Body size="micro" muted>
                                {t('shell.tagline')}
                            </Body>
                            <Heading level="h3" as="h3">
                                {t('shell.brand')}
                            </Heading>
                            <Body size="small">{t('demo.dashboard.demoCallout')}</Body>
                        </Card.Body>
                    </Card>
                </BentoGrid.Item>
            </BentoGrid>
        </section>
    );
}
