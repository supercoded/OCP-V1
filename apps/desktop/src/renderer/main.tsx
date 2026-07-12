import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { OcpServiceProvider } from "./contexts/OcpServiceContext";
import "./styles/theme.css";

const container = document.getElementById("root");
if (!container) throw new Error("No root element found");

createRoot(container).render(
  <StrictMode>
    <BrowserRouter>
      <OcpServiceProvider>
        <App />
      </OcpServiceProvider>
    </BrowserRouter>
  </StrictMode>
);
