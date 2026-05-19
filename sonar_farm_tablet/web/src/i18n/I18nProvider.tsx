// ============================================================
// Farm Sonar — Minimal i18n provider.
// ============================================================
//
// Lightweight React context that exposes `t('key.path')` to the
// whole component tree. Avoids the weight of react-i18next for
// the S4 shell scope; can be swapped later without changing the
// public API consumed by components.
//
// Locale files: `src/locales/{en,es}.json`.
// Fallback: `en` (rule .windsurf/rules/03_languages.md §i18n).
// ============================================================

import { useCallback, useMemo, useState, type ReactNode } from 'react';

import en from '@/locales/en.json';
import es from '@/locales/es.json';

import { I18nContext, type I18nContextValue, type Locale } from './context';

type LocaleTree = typeof en;

const dictionaries: Record<Locale, LocaleTree> = {
    en,
    es: es as LocaleTree,
};

function resolvePath(tree: unknown, key: string): string | undefined {
    const parts = key.split('.');
    let cursor: unknown = tree;
    for (const part of parts) {
        if (cursor === null || typeof cursor !== 'object') return undefined;
        cursor = (cursor as Record<string, unknown>)[part];
    }
    return typeof cursor === 'string' ? cursor : undefined;
}

interface I18nProviderProps {
    children: ReactNode;
    initialLocale?: Locale;
}

export function I18nProvider({ children, initialLocale = 'en' }: I18nProviderProps): JSX.Element {
    const [locale, setLocale] = useState<Locale>(initialLocale);

    const t = useCallback(
        (key: string): string => {
            const resolved =
                resolvePath(dictionaries[locale], key) ?? resolvePath(dictionaries.en, key);
            return resolved ?? key;
        },
        [locale]
    );

    const value = useMemo<I18nContextValue>(() => ({ locale, setLocale, t }), [locale, t]);

    return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}
