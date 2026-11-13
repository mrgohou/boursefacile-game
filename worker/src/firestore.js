// Écriture dans Firestore par l'API REST, avec un compte de service (secret FIREBASE_SERVICE_ACCOUNT).

const b64url = (buf) =>
  btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
const enc = (s) => b64url(new TextEncoder().encode(s));

async function accessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = enc(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = enc(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/datastore',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claim}`));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${header}.${claim}.${b64url(sig)}`,
  });
  if (!res.ok) throw new Error(`Jeton Google refusé : ${res.status}`);
  return (await res.json()).access_token;
}

/** Valeur JS → valeur Firestore REST. */
export function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}

export async function writeDoc(env, path, data) {
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const token = await accessToken(sa);
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/${env.FIRESTORE_DATABASE}/documents/${path}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ fields: toValue(data).mapValue.fields }),
  });
  if (!res.ok) throw new Error(`Écriture Firestore refusée : ${res.status} ${await res.text()}`);
}

/** Valeur Firestore REST → valeur JS. */
export function fromValue(v) {
  if ('nullValue' in v) return null;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('stringValue' in v) return v.stringValue;
  if ('arrayValue' in v) return (v.arrayValue.values ?? []).map(fromValue);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k, x]) => [k, fromValue(x)]));
  return null;
}

export async function readDoc(env, path) {
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const token = await accessToken(sa);
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/${env.FIRESTORE_DATABASE}/documents/${path}`;
  const res = await fetch(url, { headers: { authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`Lecture Firestore refusée : ${res.status}`);
  return fromValue({ mapValue: { fields: (await res.json()).fields } });
}
