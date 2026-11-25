/**
 * Web Crypto API yardımcıları (Cloudflare Workers + Node 22 uyumlu, sıfır
 * dış bağımlılık).
 */

const encoder = new TextEncoder();

export async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(input));
  const bytes = new Uint8Array(digest);
  let out = "";
  for (let i = 0; i < bytes.length; i++) {
    out += bytes[i].toString(16).padStart(2, "0");
  }
  return out;
}

export function base64UrlToBytes(segment: string): Uint8Array {
  const normalized = segment.replace(/-/g, "+").replace(/_/g, "/");
  const padLen = (4 - (normalized.length % 4)) % 4;
  const padded = normalized + "=".repeat(padLen);
  const bin = atob(padded);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) {
    out[i] = bin.charCodeAt(i);
  }
  return out;
}

export function base64UrlToJson<T = Record<string, unknown>>(segment: string): T {
  const bytes = base64UrlToBytes(segment);
  const text = new TextDecoder().decode(bytes);
  return JSON.parse(text) as T;
}

export function bytesToBase64Url(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i++) {
    bin += String.fromCharCode(bytes[i]);
  }
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

export async function verifyRs256Signature(
  jwk: JsonWebKey,
  signingInput: string,
  signatureB64Url: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const sig = base64UrlToBytes(signatureB64Url);
  return crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    sig,
    encoder.encode(signingInput),
  );
}

/** Sabit zamanlı dize karşılaştırması (RTDN gizli anahtar doğrulaması). */
export function constantTimeEqual(a: string, b: string): boolean {
  const ab = encoder.encode(a);
  const bb = encoder.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) {
    diff |= ab[i] ^ bb[i];
  }
  return diff === 0;
}
