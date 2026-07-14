import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import { OcpServiceProvider } from "./contexts/OcpServiceContext";
import "./styles/theme.css";

const container = document.getElementById("root");
if (!container) throw new Error("No root element found");

createRoot(container).render(
  <StrictMode>
    <OcpServiceProvider>
      <App />
    </OcpServiceProvider>
  </StrictMode>
);
