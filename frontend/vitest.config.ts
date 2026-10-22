import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Utilise jsdom comme environnement pour simuler le DOM du navigateur
    environment: 'jsdom',
    globals: true,
    // Motif de fichiers de test (services et intercepteurs)
    include: ['src/app/services/**/*.spec.ts', 'src/app/interceptors/**/*.spec.ts'],
    coverage: {
      reporter: ['text', 'html'],
      include: ['src/app/services/**'],
    },
  },
});
