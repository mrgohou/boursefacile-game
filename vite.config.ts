import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Chemins relatifs : le jeu fonctionne sous n'importe quel dossier d'hébergement.
  base: './',
  build: {
    rollupOptions: { input: { main: 'index.html', testeur: 'testeur.html' } },
  },
})
