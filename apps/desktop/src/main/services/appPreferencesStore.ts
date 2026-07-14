import { readFile, rename, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";

export type WorkspaceId =
  | "sonar"
  | "messaging"
  | "network"
  | "devices"
  | "spectrum"
  | "map"
  | "settings";

export interface AppPreferences {
  lastWorkspace?: WorkspaceId;
  pages: {
    sonar?: Record<string, any>;
    messaging?: Record<string, any>;
    network?: Record<string, any>;
    devices?: Record<string, any>;
    spectrum?: Record<string, any>;
    map?: Record<string, any>;
    settings?: Record<string, any>;
  };
}

const DEFAULT_PREFS: AppPreferences = {
  pages: {},
};

function isPlainObject(value: unknown): value is Record<string, any> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function mergeDeep<T extends Record<string, any>>(base: T, patch: Record<string, any>): T {
  const out: Record<string, any> = { ...base };
  for (const [key, value] of Object.entries(patch)) {
    if (isPlainObject(value) && isPlainObject(out[key])) {
      out[key] = mergeDeep(out[key], value);
    } else if (value === undefined) {
      delete out[key];
    } else {
      out[key] = value;
    }
  }
  return out as T;
}

function normalizePreferences(value: any): AppPreferences {
  const pages = isPlainObject(value?.pages) ? value.pages : {};
  return {
    ...DEFAULT_PREFS,
    lastWorkspace: value?.lastWorkspace,
    pages: {
      sonar: isPlainObject(pages.sonar) ? pages.sonar : undefined,
      messaging: isPlainObject(pages.messaging) ? pages.messaging : undefined,
      network: isPlainObject(pages.network) ? pages.network : undefined,
      devices: isPlainObject(pages.devices) ? pages.devices : undefined,
      spectrum: isPlainObject(pages.spectrum) ? pages.spectrum : undefined,
      map: isPlainObject(pages.map) ? pages.map : undefined,
      settings: isPlainObject(pages.settings) ? pages.settings : undefined,
    },
  };
}

export class AppPreferencesStore {
  #path: string;
  #preferences: AppPreferences = { ...DEFAULT_PREFS, pages: {} };
  #loaded = false;
  #writeQueue: Promise<unknown> = Promise.resolve();

  constructor(userDataPath: string) {
    this.#path = join(userDataPath, "ocp-app-preferences.json");
  }

  get preferences(): AppPreferences {
    return this.#preferences;
  }

  async load(): Promise<AppPreferences> {
    if (this.#loaded) return this.#preferences;
    try {
      const raw = await readFile(this.#path, "utf8");
      this.#preferences = normalizePreferences(JSON.parse(raw));
    } catch {
      this.#preferences = { ...DEFAULT_PREFS, pages: {} };
    }
    this.#loaded = true;
    return this.#preferences;
  }

  async save(): Promise<void> {
    await mkdir(dirname(this.#path), { recursive: true });
    const tmpPath = `${this.#path}.tmp`;
    await writeFile(tmpPath, JSON.stringify(this.#preferences, null, 2), "utf8");
    await rename(tmpPath, this.#path);
  }

  async update(patch: Partial<AppPreferences>): Promise<AppPreferences> {
    return this.#enqueue(async () => {
      await this.load();
      const sanitized = normalizePreferences(mergeDeep(this.#preferences as any, patch as any));
      this.#preferences = sanitized;
      await this.save();
      return this.#preferences;
    });
  }

  async updatePage(page: WorkspaceId, patch: Record<string, any>): Promise<AppPreferences> {
    return this.#enqueue(async () => {
      await this.load();
      const current = this.#preferences.pages[page] ?? {};
      this.#preferences = {
        ...this.#preferences,
        pages: {
          ...this.#preferences.pages,
          [page]: mergeDeep(current, patch),
        },
      };
      await this.save();
      return this.#preferences;
    });
  }

  #enqueue<T>(op: () => Promise<T>): Promise<T> {
    const run = this.#writeQueue.catch(() => undefined).then(op);
    this.#writeQueue = run.catch(() => undefined);
    return run;
  }
}
