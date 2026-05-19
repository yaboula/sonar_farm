// ============================================================
// Farm Sonar — Environment detection utilities.
// ============================================================
//
// Centralizes the "are we running inside FiveM CEF or in a normal
// browser dev session?" check so that NUI lifecycle code can branch
// on it without scattering globals checks across the codebase.
//
// In FiveM CEF, `GetParentResourceName` is injected on `window`.
// In a Vite dev browser preview, that global does not exist and we
// should default the shell to visible for designer productivity.
// ============================================================

declare global {
    interface Window {
        GetParentResourceName?: () => string;
        invokeNative?: (...args: unknown[]) => void;
    }
}

/** Returns true when running inside FiveM CEF, false in browser dev. */
export function isFiveM(): boolean {
    if (typeof window === 'undefined') return false;
    return typeof window.GetParentResourceName === 'function';
}

/** Returns true when Vite is serving the bundle in dev mode. */
export function isDev(): boolean {
    return import.meta.env.DEV === true;
}

/**
 * Resource name owning the NUI iframe. Used to build callback URLs
 * like `https://${resourceName}/close`. Falls back to the literal
 * resource name during browser dev so logs are still meaningful.
 */
export function getResourceName(): string {
    if (isFiveM() && typeof window.GetParentResourceName === 'function') {
        try {
            return window.GetParentResourceName();
        } catch {
            return 'sonar_farm_tablet';
        }
    }
    return 'sonar_farm_tablet';
}
