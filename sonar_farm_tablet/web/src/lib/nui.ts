// ============================================================
// Farm Sonar — Safe fetchNui wrapper.
// ============================================================
//
// Provides a single typed entrypoint for calling Lua NUI callbacks
// from React. Works in browser dev mode (returns a default value
// without crashing) and in FiveM CEF (POST to the resource URL).
//
// Anti-pattern §3 / DoD §6: no hardcoded resource names in
// components — components import this helper and pass the
// callback name only.
// ============================================================

import { getResourceName, isFiveM } from './env';

/**
 * Call a Lua NUI callback by name.
 *
 * In FiveM: POSTs `data` to `https://${resource}/${callback}` and
 * returns the JSON parsed response, falling back to `fallback`
 * if anything goes wrong (network, JSON parse, non-2xx).
 *
 * In browser dev: never hits the network; resolves immediately
 * with `fallback`, so devs can preview UI without Lua running.
 */
export async function fetchNui<TResponse, TPayload = Record<string, never>>(
    callback: string,
    data: TPayload = {} as TPayload,
    fallback: TResponse
): Promise<TResponse> {
    if (!isFiveM()) {
        return fallback;
    }

    const resource = getResourceName();
    const url = `https://${resource}/${callback}`;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data),
        });

        if (!response.ok) {
            return fallback;
        }

        const parsed = (await response.json()) as TResponse;
        return parsed;
    } catch {
        return fallback;
    }
}
