import { BrowserView, BrowserWindow, type Rectangle } from "electron";

/**
 * Manages an embedded BrowserView for remote WebSDR/Kiwi/OpenWebRX sessions.
 */
export class RemoteSdrSession {
  #view: BrowserView | null = null;
  #window: BrowserWindow | null = null;
  #url: string | null = null;

  get active(): boolean {
    return this.#view != null;
  }

  get url(): string | null {
    return this.#url;
  }

  async open(win: BrowserWindow, url: string, bounds: Rectangle): Promise<{ ok: boolean; error?: string }> {
    this.close();
    try {
      const view = new BrowserView({
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          sandbox: true,
        },
      });
      this.#view = view;
      this.#window = win;
      this.#url = url;
      win.addBrowserView(view);
      view.setBounds(bounds);
      await view.webContents.loadURL(url);
      return { ok: true };
    } catch (err: any) {
      this.close();
      return { ok: false, error: err?.message ?? String(err) };
    }
  }

  setBounds(bounds: Rectangle) {
    this.#view?.setBounds(bounds);
  }

  close() {
    if (this.#window && this.#view) {
      try {
        this.#window.removeBrowserView(this.#view);
      } catch {
        // window may already be destroyed
      }
    }
    if (this.#view) {
      try {
        (this.#view.webContents as any).destroy?.();
      } catch {
        // ignore
      }
    }
    this.#view = null;
    this.#window = null;
    this.#url = null;
  }
}
