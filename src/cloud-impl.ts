import { initializeApp, type FirebaseOptions } from 'firebase/app';
import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  type Auth,
  type User,
} from 'firebase/auth';
import { doc, getDoc, getFirestore, serverTimestamp, setDoc, type Firestore } from 'firebase/firestore';
import type { Save } from './store';
import type { Company } from './engine/city';

let auth: Auth;
let db: Firestore;

export function init(config: FirebaseOptions, databaseId: string) {
  const app = initializeApp(config, 'paco-bourse');
  auth = getAuth(app);
  db = getFirestore(app, databaseId);
}

export const signInGoogle = () => signInWithPopup(auth, new GoogleAuthProvider());
export const signInEmail = (email: string, password: string, create: boolean) =>
  create ? createUserWithEmailAndPassword(auth, email, password) : signInWithEmailAndPassword(auth, email, password);
export const signOutUser = () => signOut(auth);
export const onUser = (cb: (u: User | null) => void) => onAuthStateChanged(auth, cb);

// Collections du jeu, séparées de celles de l'app : game_saves/{uid}.
export async function loadSave(uid: string): Promise<Save | null> {
  const snap = await getDoc(doc(db, 'game_saves', uid));
  return snap.exists() ? (JSON.parse(snap.data().json as string) as Save) : null;
}

export async function writeSave(uid: string, s: Save) {
  // Le jeu ne stocke ni nom ni e-mail : seulement l'état de la partie.
  await setDoc(doc(db, 'game_saves', uid), { json: JSON.stringify(s), updatedAt: serverTimestamp(), version: 1 });
}

export async function readMarket(): Promise<{ sessionDate: string; companies: Company[] } | null> {
  const snap = await getDoc(doc(db, 'market_snapshots', 'latest'));
  if (!snap.exists()) return null;
  const d = snap.data();
  return { sessionDate: d.sessionDate as string, companies: d.companies as Company[] };
}
