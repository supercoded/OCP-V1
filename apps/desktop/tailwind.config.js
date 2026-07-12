/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/renderer/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "ocp-bg": "#050a0e",
        "ocp-panel": "#0d161d",
        "ocp-panel-2": "#14222d",
        "ocp-border": "#1e3342",
        "ocp-text": "#b8d4e3",
        "ocp-text-dim": "#5a7a8a",
        "ocp-accent": "#00f0a0",
        "ocp-amber": "#ffaa00",
        "ocp-red": "#ff3333",
        "ocp-grid": "#123040",
      },
      fontFamily: {
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
    },
  },
  plugins: [],
};
