/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/renderer/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // INDI/ATA gray-black palette
        "ocp-bg": "#111111",
        "ocp-panel": "#1a1a1a",
        "ocp-panel-2": "#222222",
        "ocp-panel-3": "#2a2a2a",
        "ocp-border": "#333333",
        "ocp-border-2": "#444444",
        "ocp-text": "#c8c8c8",
        "ocp-bright": "#e8e8e8",
        "ocp-dim": "#888888",
        "ocp-muted": "#666666",
        "ocp-accent": "#c8c8c8",    // was neon green, now neutral gray
        "ocp-green": "#4caf50",
        "ocp-amber": "#d4a017",
        "ocp-red": "#c62828",
        "ocp-cyan": "#4fc3f7",
        "ocp-blue": "#42a5f5",
        "ocp-grid": "#2a2a2a",
      },
      fontFamily: {
        mono: ["JetBrains Mono", "ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
    },
  },
  plugins: [],
};
