/** Simple in‑memory route table. */
export default class RouteTable {
  constructor() {
    this.routes = new Map(); // destId -> { nextHop, metric }
  }

  set(destId, { nextHop, metric = 1 }) {
    this.routes.set(destId, { nextHop, metric });
  }

  get(destId) {
    return this.routes.get(destId);
  }

  delete(destId) {
    return this.routes.delete(destId);
  }

  list() {
    return Array.from(this.routes.entries()).map(([dest, info]) => ({ dest, ...info }));
  }
}

