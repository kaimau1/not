/**
 * ORTAK ALIŞVERİŞ LİSTESİ CANLI ODASI (`ShoppingRoom` Durable Object,
 * PLAN §5.5 & §6.2 Katman 5).
 *
 * Aile / ev arkadaşı aynı anda markette madde işaretlerken <200 ms canlı
 * yayın sağlar (WebSocket). Bağlı istemci olmadığında uyur ($0 bekleme).
 */

interface WebSocketLike {
  accept?(): void;
  send(data: string): void;
  close(code?: number, reason?: string): void;
  addEventListener(type: string, listener: (event: { data?: unknown }) => void): void;
}

export class ShoppingRoom {
  private readonly sessions = new Map<WebSocketLike, { uid: string; name: string }>();

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const upgrade = request.headers.get("upgrade")?.toLowerCase();
    if (upgrade !== "websocket") {
      return new Response(
        JSON.stringify({
          activeMembers: this.sessions.size,
          room: url.pathname,
        }),
        {
          status: 200,
          headers: { "content-type": "application/json; charset=utf-8" },
        },
      );
    }

    // Cloudflare Workers runtime WebSocketPair (dinamik erişim — Node testleri için güvenli).
    const pairCtor = (globalThis as unknown as {
      WebSocketPair?: new () => { 0: WebSocketLike; 1: WebSocketLike };
    }).WebSocketPair;
    if (!pairCtor) {
      return new Response("WebSocketPair desteklenmiyor", { status: 501 });
    }

    const pair = new pairCtor();
    const client = pair[0];
    const server = pair[1];
    server.accept?.();

    const uid = request.headers.get("x-notlar-uid") || "anonymous";
    const name = request.headers.get("x-notlar-name") || "";
    this.sessions.set(server, { uid, name });

    server.addEventListener("message", (event) => {
      if (typeof event.data !== "string" || event.data.length > 16_384) return;
      let parsed: Record<string, unknown>;
      try {
        parsed = JSON.parse(event.data) as Record<string, unknown>;
      } catch {
        return;
      }
      const envelope = JSON.stringify({
        type: typeof parsed.type === "string" ? parsed.type : "item_update",
        senderUid: uid,
        senderName: name,
        ts: Date.now(),
        payload: parsed.payload ?? null,
      });
      for (const [peer] of this.sessions) {
        if (peer === server) continue;
        try {
          peer.send(envelope);
        } catch {
          this.sessions.delete(peer);
        }
      }
    });

    server.addEventListener("close", () => {
      this.sessions.delete(server);
    });

    return new Response(null, {
      status: 101,
      webSocket: client,
    } as ResponseInit);
  }
}
