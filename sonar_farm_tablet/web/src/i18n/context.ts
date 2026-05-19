// ============================================================
// Farm Sonar — i18n React context object.
// ============================================================
//
// Separated from the provider component so that Vite Fast Refresh
// can hot-reload the provider without busting the context identity.
// (react-refresh/only-export-components lint rule.)
// ============================================================

import { createContext } from 'react';

export type Locale = 'en' | 'es';

export interface I18nContextValue {
    locale: Locale;
    setLocale: (locale: Locale) => void;
    t: (key: string) => string;
}

export const I18nContext = createContext<I18nContextValue | null>(null);
