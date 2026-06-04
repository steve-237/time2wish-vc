import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Utilise jsdom comme environnement pour simuler le DOM du navigateur
    environment: 'jsdom',
    globals: true,
    // Motif de fichiers de test (services uniquement)
    include: ['src/app/services/**/*.spec.ts'],
    coverage: {
      reporter: ['text', 'html'],
      include: ['src/app/services/**'],
    },
  },
});
