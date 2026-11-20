import { defineConfig } from 'vite'
import { phoenixVitePlugin } from 'phoenix_vite'
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    // Vite's default CORS policy allows any localhost origin, which covers
    // the port that Aspire assigns to Phoenix through PORT.
  },
  optimizeDeps: {
    // https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
    include: ["live_react", "phoenix", "phoenix_html", "phoenix_live_view"],
  },
  build: {
    manifest: true,
    rolldownOptions: {
      input: ["js/app.ts", "css/app.css"],
    },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  // LV Colocated JS and Hooks
  // https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.ColocatedJS.html#module-internals
  resolve: {
    dedupe: ["react", "react-dom"],
    alias: {
      "@": ".",
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  plugins: [
    react(),
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/
    })
  ]
});
