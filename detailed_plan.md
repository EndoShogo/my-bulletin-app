# 完全実装計画書: Firebaseマルチプラットフォーム掲示板

## 1. プロジェクト概要

### 1.1. 目的
画像と一言コメントを手軽に投稿・閲覧できる、クロスプラットフォーム対応の掲示板アプリケーションを開発します。投稿はリアルタイムでWebアプリとiOSアプリ間で同期されます。

### 1.2. 対象プラットフォーム
- Web (PC/モバイルブラウザ)
- iOS (ネイティブアプリ)

### 1.3. 主要機能
- ユーザー認証 (メールアドレス/パスワード)
- テキストメッセージの投稿・表示
- 画像の投稿・表示 (※コンセプトにはありますが、初期フェーズではテキストのみに絞ります)
- リアルタイムでのデータ同期

## 2. 技術スタック

### 2.1. 共通バックエンド (Firebase)
- **Authentication**: ユーザー認証管理
- **Cloud Firestore**: テキスト投稿データ、ユーザー情報の保存 (NoSQLデータベース)
- **Cloud Storage for Firebase**: 画像ファイルの保存 (将来的な拡張用)

### 2.2. Webフロントエンド & サーバー
- **Python (Flask)**: ルーティング、HTML配信、サーバーサイドロジック
- **HTML/CSS/JavaScript**: UI構築、クライアントサイドロジック
- **Firebase Web SDK**: フロントエンドとFirebase間の通信

### 2.3. iOSクライアント
- **Swift / SwiftUI**: UI構築、ロジック
- **Firebase iOS SDK**: ネイティブアプリとFirebase間の通信

## 3. 最終的なディレクトリ構造

```
.
├── detailed_plan.md          # [このファイル]
├── web/
│   ├── requirements.txt
│   ├── app.py
│   ├── .env                    # [手動で設定] Firebase設定キー
│   ├── static/
│   │   ├── css/
│   │   │   └── style.css
│   │   └── js/
│   │       └── firebase_config.js
│   └── templates/
│       ├── base.html
│       ├── login.html
│       └── index.html
└── MyBulletinApp/
    ├── MyBulletinApp/
    │   ├── GoogleService-Info.plist # [手動で設定]
    │   ├── MyBulletinAppApp.swift
    │   ├── ContentView.swift
    │   ├── Models/
    │   │   └── Message.swift
    │   ├── ViewModels/
    │   │   └── ChatViewModel.swift
    │   └── Views/
    │       ├── LoginView.swift
    │       └── ChatView.swift
    └── ... (Xcodeプロジェクトファイル)
```

## 4. データ設計 (Cloud Firestore)

Web/iOSで共通のデータ構造を利用します。

- **Collection**: `messages`
- **Document Fields**:
  - `id` (String): Document ID (自動生成)
  - `text` (String): メッセージ本文
  - `userId` (String): 投稿者のFirebase Authentication UID
  - `userName` (String): 投稿者の表示名（メールアドレスなどを想定）
  - `createdAt` (Timestamp): サーバーサイドで記録される投稿日時

---

## 5. 実装フェーズ詳細

### Phase 1: Webアプリケーションの実装 (Flask)

**Step 1.1: 環境構築とサーバー設定**

1.  **`web/requirements.txt` の作成:**
    ```
    flask
    gunicorn
    python-dotenv
    ```
2.  **`web/app.py` の作成:**
    - Flaskアプリを初期化し、`python-dotenv`で`.env`ファイルから環境変数を読み込みます。
    - `/` (掲示板) と `/login` (ログイン) のルートを定義します。
    - `render_template` を使用してHTMLを配信する際、FirebaseのAPIキーなどを辞書としてテンプレートに渡します。これにより、クライアントサイドJSでFirebaseプロジェクトに接続できるようになります。

**Step 1.2: フロントエンドの基盤構築**

1.  **`web/templates/base.html` の作成:**
    - 全てのページの基礎となるテンプレート。
    - `app.py` から渡されたFirebase設定変数を `window.FIREBASE_CONFIG` に格納するJavaScriptコードを埋め込みます。
    - `{% block content %}` と `{% block scripts %}` を定義し、子テンプレートがコンテンツやスクリプトを挿入できるようにします。
2.  **`web/static/js/firebase_config.js` の作成:**
    - `base.html` で設定された `window.FIREBASE_CONFIG` を使用してFirebase SDKを初期化します。
    - `getAuth()` と `getFirestore()` を呼び出し、認証とデータベースのインスタンスを生成してエクスポートします。他のJSファイルからこれらをインポートして利用します。
3.  **`web/static/css/style.css` の作成:**
    - 簡単なスタイリングを適用します。(例: チャットUIの調整、フォームの整形)

**Step 1.3: 認証機能の実装**

1.  **`web/templates/login.html` の作成:**
    - メールアドレスとパスワードの入力フィールド、ログインボタンを持つフォームを作成します。
    - ログインボタンのクリックイベントで、Firebase Authenticationの `signInWithEmailAndPassword` 関数を実行するJavaScriptを記述します。
    - ログイン成功後は、自動的に掲示板ページ (`/`) にリダイレクトさせます。

**Step 1.4: 掲示板機能の実装**

1.  **`web/templates/index.html` の作成:**
    - **認証状態の監視:** `onAuthStateChanged` を使用してユーザーのログイン状態を常にチェックします。未ログインの場合は、ログインページへのリンクを表示するか、ログインページにリダイレクトします。
    - **メッセージのリアルタイム表示:** `onSnapshot` を使用して `messages` コレクションを監視します。データが追加・変更されるたびに、`createdAt` の降順で並べ替えて画面に表示します。
    - **メッセージ投稿:** テキスト入力フィールドと投稿ボタンを設置します。投稿ボタンをクリックすると、`addDoc` を使用して入力されたメッセージを `messages` コレクションに保存します。

### Phase 2: iOSアプリケーションの実装 (SwiftUI)

**Step 2.1: 初期設定とデータモデル**

1.  **Firebase SDKの初期化 (`MyBulletinAppApp.swift`):**
    - `FirebaseCore` をインポートし、アプリ起動時に `FirebaseApp.configure()` を呼び出してFirebaseプロジェクトに接続します。
2.  **データモデルの作成 (`Models/Message.swift`):**
    - Firestoreのドキュメントとマッピングするための `Message` 構造体を定義します。
    - `Identifiable`, `Codable` に準拠させ、SwiftUIの `List` やFirestoreのデコーディングで扱いやすくします。
    - `@DocumentID` と `@ServerTimestamp` プロパティラッパーを使用し、ドキュメントIDとサーバータイムスタンプを自動でマッピングします。

**Step 2.2: ViewModelの実装**

1.  **`ViewModels/ChatViewModel.swift` の作成:**
    - `ObservableObject` に準拠させ、UIに変更を通知できるようにします。
    - `@Published` プロパティとして `messages` 配列を保持します。
    - `addSnapshotListener` を使用してFirestoreの `messages` コレクションをリアルタイムで監視し、`messages` 配列を更新するロジックを実装します。
    - メッセージを送信するための `sendMessage(text: String)` 関数を定義し、内部で `addDocument` を呼び出します。

**Step 2.3: UIの実装**

1.  **`Views/LoginView.swift` の作成:**
    - メールアドレスとパスワードを入力する `TextField` と、ログイン処理をトリガーする `Button` を配置します。
2.  **`Views/ChatView.swift` の作成:**
    - `ChatViewModel` を監視し、`List` を使って `viewModel.messages` を一覧表示します。
    - 画面下部に入力用の `TextField` と送信 `Button` を配置し、`viewModel.sendMessage` を呼び出します。
3.  **`ContentView.swift` の更新:**
    - `Auth.auth().addStateDidChangeListener` を使用してユーザーの認証状態を監視します。
    - ログインしていれば `ChatView` を、していなければ `LoginView` を表示するように、ビューを動的に切り替えます。

### Phase 3: セキュリティルールの適用

開発完了後、不正なアクセスを防ぐためにFirestoreにセキュリティルールを設定します。

- **`firestore.rules`**
  ```rules
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /messages/{messageId} {
        // 読み取りは誰でも許可
        allow read: if true;
        // 作成はログインユーザーのみ、かつテキストが空でないこと
        allow create: if request.auth != null && request.resource.data.text.size() > 0;
        // 更新・削除は原則禁止
        allow update, delete: if false;
      }
    }
  }
  ```
