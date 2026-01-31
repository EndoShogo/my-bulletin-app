# My Bulletin App
- iOS版のデザイン

<img src="https://github.com/user-attachments/assets/6ebad006-c430-4de8-822d-3e005a79406d" width="24%"><img src="https://github.com/user-attachments/assets/b5c2f70f-3561-4ac7-ae7a-999b6c5b4f81" width="24%"><img src="https://github.com/user-attachments/assets/b1f0085a-6bd4-4510-8e84-7655f0ad6cee" width="24%"><img src="https://github.com/user-attachments/assets/cf6a0ecb-248c-45ee-929d-141e874c5594" width="24%">
SwiftUIのMaterial機能を多用した、軽量ながらデザイン性に優れたUI
FlaskベースのWebアプリケーションとSwiftUIベースのiOSアプリで構成される、モダンなチャット掲示板アプリケーションです。
Firebase AuthenticationとFirestoreを使用し、クロスプラットフォームでリアルタイムなコミュニケーションを提供します。

## 機能一覧

### 共通機能
- **ユーザー認証**: メールアドレス/パスワードによるログイン、新規登録、パスワードリセット
- **グループチャット**:
  - グループ作成
  - 招待コードによる参加（コードは再発行可能）
  - リアルタイムメッセージ送受信
- **ダイレクトメッセージ (DM)**:
  - ユーザー間での個別のやり取り
- **カスタマイズ**:
  - **表示名**: 自分の表示名を設定可能
  - **ニックネーム**: 相手の名前を自分好みにローカル設定（相手には通知されません）
  - **背景設定**: チャットごとに背景色または画像（iOSのみ）を設定可能

### iOS版独自機能
- **Liquid Glass Design**: Apple純正アプリのような美しいすりガラス調のデザイン
- **ジェスチャー操作**:
  - メッセージ入力欄のスワイプでキーボード開閉
  - 画面左端スワイプで戻る（標準動作）
- **画像送信**: チャットでの画像共有
- **ホーム画面装飾**: タップで色が変化するインタラクティブなアイコン

### Web版機能
- **レスポンシブデザイン**: PC/モバイル両対応のモダンなUI
- **テーマ切り替え**: ライト/ダーク/システム設定の切り替え
- **背景色設定**: 7色のパステルカラーから選択可能

## 技術スタック

### Web / Backend
- **Language**: Python 3.x
- **Framework**: Flask
- **Frontend**: HTML5, CSS3 (Vanilla), JavaScript (ES modules)
- **Database**: Firebase Firestore
- **Auth**: Firebase Authentication

### iOS
- **Language**: Swift 5.x
- **Framework**: SwiftUI
- **Minimum OS**: iOS 16.0+
- **Database**: Firebase Firestore
- **Auth**: Firebase Authentication

## セットアップ手順

### 前提条件
Firebaseプロジェクトを作成し、Authentication（Email/Password）とFirestoreを有効にしておいてください。

### Web版
1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/EndoShogo/my-bulletin-app.git
   cd my-bulletin-app
   ```

2. **依存関係のインストール**
   ```bash
   pip install -r web/requirements.txt
   ```

3. **Firebase設定**
   `web/static/js/firebase_config.js` を作成し、Firebaseコンソールから取得したWebアプリの設定を貼り付けてください。

4. **起動**
   ```bash
   python web/app.py
   ```
   ブラウザで `http://localhost:5001` にアクセスします。

### iOS版
1. **Xcodeプロジェクトを開く**
   `MyBulletinApp/MyBulletinApp.xcodeproj` をXcodeで開きます。

2. **Firebase設定**
   Firebaseコンソールから `GoogleService-Info.plist` をダウンロードし、`MyBulletinApp/MyBulletinApp/` フォルダに追加してください（Xcode上のプロジェクトナビゲータにもドラッグ＆ドロップ）。

3. **パッケージの信頼**
   初回オープン時、Swift Package Managerが自動的にFirebase SDKなどの依存関係を解決します。完了まで待ちます。

4. **ビルド & 実行**
   iOSシミュレーターまたは実機を選択して実行（Cmd+R）します。

## ライセンス
[MIT License](LICENSE)
