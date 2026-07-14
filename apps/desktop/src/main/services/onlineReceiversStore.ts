import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";

export interface OnlineReceiversPrefs {
  favoriteIds: string[];
  lastReceiverId?: string;
}

const DEFAULT_PREFS: OnlineReceiversPrefs = { favoriteIds: [] };

export class OnlineReceiversStore {
  #path: string;
  #prefs: OnlineReceiversPrefs = { ...DEFAULT_PREFS };

  constructor(userDataPath: string) {
    this.#path = join(userDataPath, "online-receivers-prefs.json");
  }

  async load() {
    try {
      const raw = await readFile(this.#path, "utf8");
      const parsed = JSON.parse(raw) as OnlineReceiversPrefs;
      this.#prefs = {
        favoriteIds: Array.isArray(parsed.favoriteIds) ? parsed.favoriteIds : [],
        lastReceiverId: parsed.lastReceiverId,
      };
    } catch {
      this.#prefs = { ...DEFAULT_PREFS };
    }
    return this.#prefs;
  }

  async save() {
    await mkdir(dirname(this.#path), { recursive: true });
    await writeFile(this.#path, JSON.stringify(this.#prefs, null, 2), "utf8");
  }

  get prefs() {
    return this.#prefs;
  }

  async toggleFavorite(id: string) {
    const set = new Set(this.#prefs.favoriteIds);
    if (set.has(id)) set.delete(id);
    else set.add(id);
    this.#prefs.favoriteIds = [...set];
    await this.save();
    return this.#prefs.favoriteIds;
  }

  async setLastReceiver(id: string | undefined) {
    this.#prefs.lastReceiverId = id;
    await this.save();
  }
}
