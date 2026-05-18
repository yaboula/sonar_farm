import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from '@/App';
import '@/styles/theme.css';
import '@/styles/globals.css';

const rootElement = document.getElementById('root');

if (!rootElement) {
    throw new Error(
        '[sonar_farm_tablet] #root not found. Check index.html.'
    );
}

createRoot(rootElement).render(
    <StrictMode>
        <App />
    </StrictMode>
);
