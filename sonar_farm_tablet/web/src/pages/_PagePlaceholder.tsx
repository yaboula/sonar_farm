// ============================================================
// Farm Sonar — Internal placeholder helper for route stubs.
// ============================================================
//
// Used by all S4 pages that do NOT yet have their slice implemented.
// Renders a heading + EmptyState with i18n strings from
// `page.<key>.*` + `state.empty.*` namespaces.
//
// Underscore-prefixed file name to make its non-public role
// explicit: only the route pages should import this; downstream
// slices implement their own page bodies and drop this helper.
// ============================================================

import { Inbox } from 'lucide-react';

import { Body } from '@/components/typography/Body';
import { Heading } from '@/components/typography/Heading';
import { EmptyState } from '@/components/ui/EmptyState';
import { Icon } from '@/components/ui/Icon';
import { useI18n } from '@/i18n';

interface PagePlaceholderProps {
    pageKey: string;
}

export function PagePlaceholder({ pageKey }: PagePlaceholderProps): JSX.Element {
    const { t } = useI18n();
    return (
        <section className="fs-fade-in flex flex-col gap-6">
            <header className="flex flex-col gap-1">
                <Heading level="h1" as="h1">
                    {t(`page.${pageKey}.title`)}
                </Heading>
                <Body size="small" muted>
                    {t(`page.${pageKey}.subtitle`)}
                </Body>
            </header>

            <EmptyState
                icon={<Icon as={Inbox} size="xl" />}
                title={t('state.empty.title')}
                body={t('state.empty.body')}
            />
        </section>
    );
}
