import { defineConfig } from "vitest/config"
import react from "@vitejs/plugin-react"

// Kept apart from vite.config.mjs so that tests do not load the Phoenix and
// Tailwind plugins, which need the Mix build environment.
export default defineConfig({
  plugins: [react()],
  resolve: {
    dedupe: ["react", "react-dom"],
  },
  test: {
    environment: "jsdom",
    setupFiles: ["js/test/setup.ts"],
    include: ["js/**/*.test.{ts,tsx}"],
  },
})
