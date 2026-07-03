import { mkdir, writeFile } from "node:fs/promises";
import { JsonFileOfflineStore, LocalKeyCipher } from "../../../packages/offline-core/src/storage/index.js";

async function boot() {
  await mkdir("dist/desktop-runtime", { recursive: true });
  const store = new JsonFileOfflineStore({
    dbPath: "dist/desktop-runtime/offline-db.json",
    keyCipher: new LocalKeyCipher(process.env.OCP_KEY_PASSPHRASE ?? "dev-only-passphrase")
  });
  await store.init();
  await writeFile(
    "dist/desktop-runtime/status.txt",
    "Desktop runtime initialized with offline store.\n",
    "utf8"
  );
  console.log("Offline desktop runtime initialized.");
}

boot().catch((error) => {
  console.error("Desktop startup failed:", error);
  process.exitCode = 1;
});
