# Flask Webアプリ実装計画書: テキスト掲示板

## 1. プロジェクト概要

### 1.1. 目的
Firebase AuthenticationとCloud Firestoreを使用した、リアルタイムテキスト掲示板のWebアプリケーションをFlaskで実装します。クライアントサイドでFirebase SDKを使用し、サーバーサイドはHTMLの配信とFirebase設定の注入を行います。

### 1.2. 技術スタック
- **サーバーサイド**: Python (Flask)
- **フロントエンド**: HTML/CSS/JavaScript
- **バックエンド**: Firebase
  - Firebase Authentication (メール/パスワード認証)
  - Cloud Firestore (リアルタイムデータベース)
- **依存関係管理**: pip (requirements.txt)

### 1.3. 現在の状態
- `web/.env` ファイルが存在（Firebase設定キーを含む）
- その他のファイルは未実装

## 2. ディレクトリ構造

```
web/
├── .env                        # [既存] Firebase設定キー（手動設定済み）
├── requirements.txt            # [新規作成] 依存ライブラリ定義
├── app.py                      # [新規作成] Flaskサーバー (エントリーポイント)
├── static/
│   ├── css/
│   │   └── style.css          # [新規作成] スタイルシート
│   └── js/
│       └── firebase_config.js # [新規作成] Firebase初期化・Config連携
└── templates/
    ├── base.html              # [新規作成] 共通レイアウト (環境変数渡し)
    ├── login.html             # [新規作成] ログイン画面
    └── index.html             # [新規作成] チャット一覧・投稿画面
```

## 3. データ設計 (Cloud Firestore)

iOSアプリと共通のデータ構造を使用します。

- **Collection**: `messages`
- **Document Fields**:
  - `id` (String): Document ID (自動生成)
  - `text` (String): メッセージ本文
  - `userId` (String): 投稿者のFirebase Authentication UID
  - `userName` (String): 投稿者の表示名
  - `createdAt` (Timestamp): サーバーサイドで記録される投稿日時

## 4. 実装ステップ

### Step 1: 依存関係とサーバー設定

#### 1.1. `requirements.txt` の作成

**実装内容**:
```txt
flask
gunicorn
python-dotenv
```

**説明**:
- `flask`: Webフレームワーク
- `gunicorn`: 本番環境用WSGIサーバー（開発時は`flask run`でも可）
- `python-dotenv`: `.env`ファイルから環境変数を読み込む

#### 1.2. `app.py` の作成

**実装要件**:

1. **Flaskアプリの初期化**:
   - `Flask(__name__)`でアプリインスタンスを作成
   - `python-dotenv`を使用して`.env`ファイルをロード

2. **Firebase設定の準備**:
   - `.env`から以下の環境変数を読み込む関数を作成:
     - `FIREBASE_API_KEY`
     - `FIREBASE_AUTH_DOMAIN`
     - `FIREBASE_PROJECT_ID`
     - `FIREBASE_STORAGE_BUCKET`
     - `FIREBASE_MESSAGING_SENDER_ID`
     - `FIREBASE_APP_ID`
   - これらを辞書形式でまとめる関数 `get_firebase_config()` を作成

3. **ルート定義**:
   - `/` (index): 掲示板画面を表示
     - `render_template('index.html', firebase_config=get_firebase_config())`
   - `/login`: ログイン画面を表示
     - `render_template('login.html', firebase_config=get_firebase_config())`

**実装のポイント**:
- 環境変数が存在しない場合のエラーハンドリング
- 開発モードでのデバッグ設定（`app.run(debug=True)`）

### Step 2: フロントエンド基盤

#### 2.1. `templates/base.html` の作成

**実装要件**:

1. **基本HTML構造**:
   - `<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`タグ
   - 文字コード設定（UTF-8）
   - レスポンシブ対応のviewport設定

2. **Firebase設定の注入**:
   - Flaskから渡された`firebase_config`を`window.FIREBASE_CONFIG`に代入するJavaScriptコードを`<script>`タグ内に記述
   ```javascript
   <script>
     window.FIREBASE_CONFIG = {{ firebase_config | tojson }};
   </script>
   ```

3. **ブロック定義**:
   - `{% block content %}{% endblock %}`: ページコンテンツ用
   - `{% block scripts %}{% endblock %}`: ページ固有のスクリプト用

4. **共通リソースの読み込み**:
   - `style.css`の読み込み
   - Firebase SDKのCDN読み込み（v9/v10 Modular形式）
   - `firebase_config.js`の読み込み

**実装のポイント**:
- Jinja2テンプレートエンジンの構文を使用
- `tojson`フィルターでPython辞書をJSONに変換

#### 2.2. `static/js/firebase_config.js` の作成

**実装要件**:

1. **Firebase SDKのインポート**:
   - Firebase SDK v9/v10 Modular形式をCDNからインポート
   ```javascript
   import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.x.x/firebase-app.js';
   import { getAuth } from 'https://www.gstatic.com/firebasejs/10.x.x/firebase-auth.js';
   import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.x.x/firebase-firestore.js';
   ```

2. **Firebase初期化**:
   - `window.FIREBASE_CONFIG`を使用して`initializeApp`を実行
   - `getAuth()`と`getFirestore()`を呼び出し、インスタンスを生成

3. **エクスポート**:
   - `auth`と`db`（Firestoreインスタンス）をエクスポート
   - 他のJSファイルからインポートして使用可能にする

**実装のポイント**:
- モジュール形式で実装し、他のJSファイルから再利用可能にする
- エラーハンドリング（設定が存在しない場合など）

#### 2.3. `static/css/style.css` の作成

**実装要件**:

1. **基本スタイル**:
   - リセットCSS（オプション）
   - フォント設定
   - カラースキームの定義

2. **レイアウト**:
   - コンテナの中央揃え
   - レスポンシブデザイン

3. **コンポーネントスタイル**:
   - フォーム要素のスタイル（入力フィールド、ボタン）
   - チャットメッセージの表示スタイル
   - ログイン画面のスタイル

**実装のポイント**:
- モダンなUIデザイン（オプション）
- モバイル対応

### Step 3: 認証機能の実装

#### 3.1. `templates/login.html` の作成

**実装要件**:

1. **テンプレート継承**:
   - `{% extends "base.html" %}`で`base.html`を継承

2. **UI要素**:
   - メールアドレス入力用の`<input type="email">`
   - パスワード入力用の`<input type="password">`
   - ログインボタン
   - エラーメッセージ表示エリア（初期状態は非表示）

3. **JavaScript実装**:
   - `firebase_config.js`から`auth`をインポート
   - `signInWithEmailAndPassword(auth, email, password)`を実行
   - ログイン成功時: `window.location.href = '/'`でリダイレクト
   - ログイン失敗時: エラーメッセージを表示

**実装のポイント**:
- フォーム送信のデフォルト動作を防止（`preventDefault()`）
- ローディング状態の表示（オプション）
- エラーメッセージのユーザーフレンドリーな表示

### Step 4: 掲示板機能の実装

#### 4.1. `templates/index.html` の作成

**実装要件**:

1. **テンプレート継承**:
   - `{% extends "base.html" %}`で`base.html`を継承

2. **認証状態の監視**:
   - `onAuthStateChanged(auth, (user) => {...})`を使用
   - 未ログイン時: ログインページへのリンクまたはリダイレクトを表示
   - ログイン時: 掲示板機能を表示

3. **メッセージ表示エリア**:
   - `<div id="messages-container">`を作成
   - `onSnapshot`を使用して`messages`コレクションをリアルタイム監視
   - クエリ: `orderBy('createdAt', 'desc')`で降順ソート
   - DOM操作でメッセージを動的に追加・更新

4. **メッセージ投稿フォーム**:
   - テキスト入力用の`<textarea>`または`<input>`
   - 投稿ボタン
   - 送信処理:
     - `addDoc(collection(db, 'messages'), {...})`を実行
     - フィールド: `text`, `userId`, `userName`, `createdAt`（サーバータイムスタンプ）
     - 送信後、入力フィールドをクリア

5. **ログアウト機能**（オプション）:
   - ログアウトボタンを配置
   - `signOut(auth)`を実行

**実装のポイント**:
- リスナーの適切な管理（クリーンアップ）
- メッセージの表示形式（ユーザー名、テキスト、タイムスタンプ）
- 空のメッセージ送信の防止
- エラーハンドリング

## 5. 環境変数の設定

### 5.1. `.env` ファイルの確認

以下の環境変数が設定されていることを確認:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

### 5.2. 環境変数の取得方法

Firebase Consoleから取得:
1. Firebase Consoleにログイン
2. プロジェクト設定 → 全般 → アプリ
3. Webアプリの設定から必要な情報を取得

## 6. 実装の優先順位

### Phase 1: 基本機能の実装
1. `requirements.txt`の作成
2. `app.py`の実装（環境変数読み込み、ルート定義）
3. `base.html`の実装
4. `firebase_config.js`の実装
5. `login.html`の実装
6. `index.html`の実装（認証、表示、投稿）

### Phase 2: スタイリングとUX改善
1. `style.css`の実装
2. ローディング状態の表示
3. エラーメッセージの改善
4. レスポンシブデザインの調整

### Phase 3: 追加機能（オプション）
1. ログアウト機能
2. ユーザー登録機能
3. メッセージ削除機能（本人のみ）
4. プルリフレッシュ機能

## 7. 動作確認項目

### 7.1. サーバー起動
- [ ] `pip install -r requirements.txt`で依存関係をインストール
- [ ] `flask run`または`python app.py`でサーバーが起動する
- [ ] `http://localhost:5000`にアクセスできる

### 7.2. 認証機能
- [ ] ログイン画面が表示される
- [ ] 正しいメール/パスワードでログインできる
- [ ] ログイン失敗時にエラーが表示される
- [ ] ログイン成功時に掲示板画面にリダイレクトされる

### 7.3. 掲示板機能
- [ ] 未ログイン時にログインリンクが表示される
- [ ] メッセージ一覧がリアルタイムで更新される
- [ ] メッセージが新しい順（降順）で表示される
- [ ] メッセージ送信が正常に動作する
- [ ] 送信後、入力フィールドがクリアされる
- [ ] ユーザー名とメッセージ本文が正しく表示される

### 7.4. データ同期
- [ ] Webアプリで送信したメッセージがFirestoreに保存される
- [ ] 複数のブラウザで開いた場合、リアルタイムで同期される

## 8. トラブルシューティング

### 8.1. よくある問題

1. **環境変数が読み込まれない**:
   - `.env`ファイルが`web/`ディレクトリに存在するか確認
   - `python-dotenv`が正しくインストールされているか確認

2. **Firebase初期化エラー**:
   - `window.FIREBASE_CONFIG`が正しく設定されているか確認
   - ブラウザのコンソールでエラーメッセージを確認

3. **認証エラー**:
   - Firebase ConsoleでAuthenticationが有効になっているか確認
   - メール/パスワード認証が有効になっているか確認

4. **Firestore接続エラー**:
   - Firestoreが有効になっているか確認
   - セキュリティルールが適切に設定されているか確認（開発中はテストモード推奨）

## 9. 参考リソース

- [Flask公式ドキュメント](https://flask.palletsprojects.com/)
- [Firebase Web SDK ドキュメント](https://firebase.google.com/docs/web/setup)
- [Firebase Authentication ドキュメント](https://firebase.google.com/docs/auth/web/start)
- [Cloud Firestore Web ドキュメント](https://firebase.google.com/docs/firestore/quickstart)

## 10. 注意事項

1. **セキュリティ**:
   - `.env`ファイルをGitにコミットしない（`.gitignore`に追加）
   - 本番環境では環境変数を適切に管理する

2. **Firestoreセキュリティルール**:
   - 開発中はテストモードを使用
   - 本番環境では適切なセキュリティルールを設定（`plan.md`のPhase 3を参照）

3. **CORS設定**:
   - 必要に応じてCORS設定を追加（他のドメインからアクセスする場合）

4. **パフォーマンス**:
   - メッセージが大量になった場合のページネーション検討
   - リスナーの適切なクリーンアップ
