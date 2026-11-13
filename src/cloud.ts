// Firebase : compte partagé avec l'app Bourse Facile, sauvegarde en ligne, cours du jour.
// Chargé à la demande (import dynamique) pour garder le jeu léger.
import type { User } from 'firebase/auth';
import type { Save } from './store';
import type { Company } from './engine/city';

// Identifiants publics du client web, les mêmes que l'app (lib/data/account_config.dart).
const CONFIG = {
  apiKey: 'AIzaSyDPfpwxyJNsDLOH69jlOq6PLbjJN1yemkE',
  authDomain: 'third-storm-9w532.firebaseapp.com',
  projectId: 'third-storm-9w532',
};
// Base Firestore nommée de Bourse Facile.
const DATABASE_ID = 'ai-studio-bourseclair-8beb427d-785b-41cf-b1ba-358589ed533a';

/** Les comptes ne marchent que sur un domaine autorisé dans Firebase Auth (pas dans un aperçu intégré). */
export function cloudAvailable() {
  const h = location.hostname;
  return h === 'localhost' || h.endsWith('.web.app') || h.endsWith('.firebaseapp.com') || h.endsWith('boursefacile.ai.studio');
}

let ready: Promise<typeof import('./cloud-impl')> | null = null;
function impl() {
  ready ??= import('./cloud-impl').then((m) => (m.init(CONFIG, DATABASE_ID), m));
  return ready;
}

export async function signInGoogle() {
  return (await impl()).signInGoogle();
}
export async function signInEmail(email: string, password: string, create: boolean) {
  return (await impl()).signInEmail(email, password, create);
}
export async function signOut() {
  return (await impl()).signOutUser();
}
export async function onUser(cb: (u: User | null) => void) {
  return (await impl()).onUser(cb);
}
export async function loadCloudSave(uid: string): Promise<Save | null> {
  return (await impl()).loadSave(uid);
}
export async function saveCloud(uid: string, s: Save) {
  return (await impl()).writeSave(uid, s);
}
/** Instantané de marché publié chaque jour (market_snapshots/latest). null si absent. */
export async function loadMarket(): Promise<{ sessionDate: string; companies: Company[] } | null> {
  try {
    return await (await impl()).readMarket();
  } catch {
    return null;
  }
}
export async function sendFeedback(uid: string, city: number, f: object) {
  return (await impl()).writeFeedback(uid, city, f);
}
