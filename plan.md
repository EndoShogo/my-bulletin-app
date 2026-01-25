
# 実装計画書: テキスト掲示板 (Flask & SwiftUI)

## 1. プロジェクト構成のゴール

現在のディレクトリ構造に対し、以下のファイル群を順次作成・実装していく。

```text
.
├── web/                          # [Phase 1: Web実装]
│   ├── requirements.txt          # 依存ライブラリ定義
│   ├── app.py                    # Flaskサーバー (エントリーポイント)
│   ├── static/
│   │   ├── css/
│   │   │   └── style.css         # 簡易スタイル
│   │   └── js/
│   │       └── firebase_config.js # Firebase初期化・Config連携
│   └── templates/
│       ├── base.html             # 共通レイアウト (環境変数渡し)
│       ├── login.html            # ログイン画面
│       └── index.html            # チャット一覧・投稿画面
│
└── MyBulletinApp/                # [Phase 2: iOS実装]
    └── MyBulletinApp/
        ├── Models/               # [新規]
        │   └── Message.swift     # データモデル (Codable)
        ├── ViewModels/           # [新規]
        │   └── ChatViewModel.swift # Firestore通信ロジック
        └── Views/                # [新規]
            ├── LoginView.swift   # ログインUI
            └── ChatView.swift    # チャットUI

```

## 2. データ設計 (Firestore)

Web/iOS共通で以下のデータ構造を使用する。

* **Collection**: `messages`
* **Document Definition**:
* `id`: String (Document ID)
* `text`: String (メッセージ本文)
* `userId`: String (投稿者のUID)
* `userName`: String (表示名)
* `createdAt`: Timestamp (サーバータイムスタンプ)



---

## Phase 1: Webアプリケーションの実装 (Flask)

Web側を先に実装し、データの疎通確認を行えるようにする。

### Step 1.1: 依存関係とサーバー設定

**Target: `web/requirements.txt**`

* 以下のライブラリを含めること:
* `flask`: Webフレームワーク
* `gunicorn`: 本番サーバー用
* `python-dotenv`: 環境変数読み込み用



**Target: `web/app.py**`

* **役割**: HTMLの配信と環境変数の注入。
* **実装要件**:
1. `python-dotenv` で `.env` をロードする。
2. 環境変数 (`FIREBASE_API_KEY` 等) を辞書形式でまとめる関数を作成する。
3. ルート `/` (index) と `/login` を作成し、`render_template` でHTMLを返す際に、上記の設定辞書を `firebase_config` という変数名で渡す。



### Step 1.2: フロントエンド基盤

**Target: `web/templates/base.html**`

* **役割**: 全ページの親テンプレート。
* **実装要件**:
1. Flaskから渡された `firebase_config` を `window.FIREBASE_CONFIG` に代入する `<script>` タグを配置する（これでJSから環境変数を参照可能にする）。
2. `{% block content %}` と `{% block scripts %}` を定義する。



**Target: `web/static/js/firebase_config.js**`

* **役割**: Firebase SDKの初期化。
* **実装要件**:
1. Firebase SDK (v9/v10 Modular) をCDNからインポートする。
2. `window.FIREBASE_CONFIG` を使って `initializeApp` を実行する。
3. `getAuth`, `getFirestore` を初期化し、exportする。



### Step 1.3: 画面機能の実装

**Target: `web/templates/login.html**`

* **実装要件**:
1. Email/Password入力フォームを作成。
2. `signInWithEmailAndPassword` (Firebase Auth) を実行するJSを書く。
3. ログイン成功時に `/` へリダイレクトする。



**Target: `web/templates/index.html**`

* **実装要件**:
1. **表示**: `onSnapshot` (Firestore) を使い `messages` コレクションを `createdAt` 降順で監視。DOMをリアルタイム更新する。
2. **投稿**: 入力フォームを設置し、`addDoc` でFirestoreへ保存する。
3. **認証ガード**: `onAuthStateChanged` でログイン状態を確認し、未ログインならログインページへのリンクを表示する。



---

## Phase 2: iOSアプリケーションの実装 (SwiftUI)

Webで作ったデータ構造に合わせてネイティブアプリを実装する。

### Step 2.1: 初期設定

**Target: `MyBulletinApp/MyBulletinApp/MyBulletinAppApp.swift**`

* **実装要件**:
1. `FirebaseCore` をインポート。
2. `AppDelegate` または `init` 内で `FirebaseApp.configure()` を呼び出す。



### Step 2.2: データモデル

**Target: `MyBulletinApp/MyBulletinApp/Models/Message.swift**`

* **実装要件**:
1. `Identifiable`, `Codable` に準拠した構造体 `Message` を定義。
2. `@DocumentID` プロパティラッパーを使用してIDを管理する。
3. `createdAt` は `Date?` 型とし、`@ServerTimestamp` を付与する。



### Step 2.3: ロジック (ViewModel)

**Target: `MyBulletinApp/MyBulletinApp/ViewModels/ChatViewModel.swift**`

* **役割**: データの取得と送信。
* **実装要件**:
1. `ObservableObject` に準拠。
2. `@Published var messages: [Message]` を持つ。
3. `init` で `fetchMessages()` を呼ぶ。
4. **取得**: `addSnapshotListener` でリアルタイム更新を受け取り、`messages` 配列を更新する。
5. **送信**: `sendMessage(text: String)` 関数を作成し、`addDocument` でFirestoreに書き込む。



### Step 2.4: UI実装

**Target: `MyBulletinApp/MyBulletinApp/Views/LoginView.swift**`

* **実装要件**:
1. Email/Passwordの `TextField`。
2. ボタンタップで `Auth.auth().signIn` を実行。



**Target: `MyBulletinApp/MyBulletinApp/Views/ChatView.swift**`

* **実装要件**:
1. `List` で `viewModel.messages` を表示。
2. 画面下部にテキスト入力エリアと送信ボタンを配置。
3. 送信ボタンのアクションで `viewModel.sendMessage` を実行。



**Target: `MyBulletinApp/MyBulletinApp/ContentView.swift**`

* **実装要件**:
1. `Auth.auth().currentUser` の有無、またはリスナーを使って、`LoginView` と `ChatView` を切り替えて表示する。



---

## Phase 3: セキュリティルール (Firestore)

開発完了後、以下のルールを適用する。

**Target: `firebase/firestore.rules**`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /messages/{messageId} {
      // 読み取りは誰でも許可
      allow read: if true;
      // 作成はログインユーザーのみ、かつテキストが空でないこと
      allow create: if request.auth != null && request.resource.data.text.size() > 0;
      // 削除・更新は禁止（または本人のみ許可）
      allow update, delete: if false; 
    }
  }
}

```