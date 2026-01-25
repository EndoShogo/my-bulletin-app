// Firebase SDKの必要なモジュールをインポート
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

// base.htmlから渡された設定でFirebaseアプリを初期化
const firebaseApp = initializeApp(window.FIREBASE_CONFIG);

// 他のファイルで使用するためにAuthとFirestoreのインスタンスをエクスポート
export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
