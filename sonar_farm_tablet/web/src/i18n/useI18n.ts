// ============================================================
// Farm Sonar — useI18n hook.
// ============================================================
//
// Consumer hook for the I18nProvider context. Throws when used
// outside the provider so we catch wiring bugs in dev fast.
// ============================================================

import { useContext } from 'react';

import { I18nContext, type I18nContextValue } from './context';

export function useI18n(): I18nContextValue {
    const context = useContext(I18nContext);
    if (!context) {
        throw new Error('[sonar_farm_tablet] useI18n called outside I18nProvider.');
    }
    return context;
}
