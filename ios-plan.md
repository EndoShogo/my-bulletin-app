# iOSアプリ実装計画書: テキスト掲示板 (SwiftUI + Firebase)

## 1. プロジェクト概要

### 1.1. 目的
Webアプリとリアルタイムで同期するiOSネイティブアプリを実装します。Firebase Authenticationで認証し、Cloud Firestoreでメッセージデータを管理します。

### 1.2. 技術スタック
- **言語**: Swift 
- **UIフレームワーク**: SwiftUI
- **バックエンド**: Firebase
  - Firebase Authentication (メール/パスワード認証)
  - Cloud Firestore (リアルタイムデータベース)
- **依存関係管理**: [要確認] Swift Package Manager / CocoaPods

## 2. ディレクトリ構造

```
MyBulletinApp/
└── MyBulletinApp/
    ├── GoogleService-Info.plist      # [既存] Firebase設定ファイル
    ├── MyBulletinAppApp.swift        # [既存・要更新] アプリエントリーポイント
    ├── ContentView.swift              # [既存・要更新] 認証状態に応じた画面切り替え
    ├── Models/                        # [新規作成]
    │   └── Message.swift             # メッセージデータモデル
    ├── ViewModels/                    # [新規作成]
    │   └── ChatViewModel.swift       # Firestore通信ロジック
    └── Views/                         # [新規作成]
        ├── LoginView.swift           # ログイン画面
        └── ChatView.swift            # チャット一覧・投稿画面
```

## 3. データ設計 (Cloud Firestore)

Webアプリと共通のデータ構造を使用します。

- **Collection**: `messages`
- **Document Fields**:
  - `id` (String): Document ID (自動生成)
  - `text` (String): メッセージ本文
  - `userId` (String): 投稿者のFirebase Authentication UID
  - `userName` (String): 投稿者の表示名
  - `createdAt` (Timestamp): サーバーサイドで記録される投稿日時

## 4. 実装ステップ

### Step 1: 依存関係の設定

#### 1.1. Firebase SDKの追加

**方法A: Swift Package Manager (推奨)**
1. Xcodeでプロジェクトを開く
2. `File` → `Add Package Dependencies...`
3. 以下のパッケージを追加:
   - `https://github.com/firebase/firebase-ios-sdk`
   - 必要なプロダクト:
     - `FirebaseAuth`
     - `FirebaseFirestore`
     - `FirebaseCore` (既に追加済みの可能性あり)

**方法B: CocoaPods**
1. `Podfile`を作成し、以下を追加:
   ```ruby
   pod 'FirebaseAuth'
   pod 'FirebaseFirestore'
   ```

**確認事項**: [要確認] 使用する依存関係管理方法

#### 1.2. インポート文の確認

各ファイルで必要なモジュールをインポート:
- `import SwiftUI`
- `import FirebaseCore`
- `import FirebaseAuth`
- `import FirebaseFirestore`

### Step 2: データモデルの実装

#### 2.1. `Models/Message.swift` の作成

**実装要件**:
1. `Identifiable` プロトコルに準拠（SwiftUIの`List`で使用）
2. `Codable` プロトコルに準拠（Firestoreとの相互変換）
3. プロパティ定義:
   - `@DocumentID var id: String?` - FirestoreのドキュメントID
   - `var text: String` - メッセージ本文
   - `var userId: String` - 投稿者のUID
   - `var userName: String` - 投稿者の表示名
   - `@ServerTimestamp var createdAt: Date?` - サーバータイムスタンプ

**注意点**:
- `@DocumentID`と`@ServerTimestamp`は`FirebaseFirestoreSwift`から提供されるプロパティラッパー
- `FirebaseFirestoreSwift`パッケージも追加が必要な場合あり

### Step 3: ViewModelの実装

#### 3.1. `ViewModels/ChatViewModel.swift` の作成

**実装要件**:
1. `ObservableObject`プロトコルに準拠
2. `@Published var messages: [Message] = []` - メッセージ配列
3. `@Published var isLoading: Bool = false` - ローディング状態（オプション）
4. `@Published var errorMessage: String?` - エラーメッセージ（オプション）

**メソッド**:
1. `init()` - 初期化時に`fetchMessages()`を呼び出す
2. `fetchMessages()` - Firestoreの`messages`コレクションをリアルタイム監視
   - `addSnapshotListener`を使用
   - `createdAt`の降順でソート
   - エラーハンドリングを実装
3. `sendMessage(text: String)` - メッセージを送信
   - 現在のユーザー情報を取得（`Auth.auth().currentUser`）
   - `addDocument`でFirestoreに保存
   - エラーハンドリングを実装
4. `signOut()` - ログアウト処理（オプション）

**実装のポイント**:
- リスナーの管理: `addSnapshotListener`の戻り値を保持し、適切に削除する
- エラーハンドリング: `do-catch`文でエラーをキャッチし、ユーザーに通知

### Step 4: UI実装

#### 4.1. `Views/LoginView.swift` の作成

**実装要件**:
1. 状態管理:
   - `@State private var email: String = ""`
   - `@State private var password: String = ""`
   - `@State private var isLoading: Bool = false`
   - `@State private var errorMessage: String?`

2. UI要素:
   - Email入力用の`TextField`
   - Password入力用の`SecureField`
   - ログインボタン
   - エラーメッセージ表示（`errorMessage`が存在する場合）

3. ログイン処理:
   - ボタンタップで`Auth.auth().signIn(withEmail:password:)`を実行
   - 成功時: 自動的に`ChatView`へ遷移（`ContentView`で制御）
   - 失敗時: エラーメッセージを表示

**UIデザイン**: [要確認] デザイン要件があれば反映

#### 4.2. `Views/ChatView.swift` の作成

**実装要件**:
1. ViewModelの統合:
   - `@StateObject private var viewModel = ChatViewModel()`

2. メッセージ表示:
   - `List`または`ScrollView` + `LazyVStack`でメッセージ一覧を表示
   - `createdAt`の降順（新しい順）で表示
   - 各メッセージに`userName`と`text`を表示
   - タイムスタンプの表示（オプション）

3. 投稿機能:
   - 画面下部に`TextField`と送信ボタンを配置
   - `@State private var messageText: String = ""`で入力状態を管理
   - 送信ボタンタップで`viewModel.sendMessage(text: messageText)`を実行
   - 送信後、入力フィールドをクリア

4. 認証状態の確認:
   - 未ログイン時は適切なメッセージを表示

**UIデザイン**: [要確認] チャット形式、カード形式など希望があれば反映

#### 4.3. `ContentView.swift` の更新

**実装要件**:
1. 認証状態の監視:
   - `@State private var isAuthenticated: Bool = false`
   - `onAppear`または`init`で`Auth.auth().addStateDidChangeListener`を設定
   - 認証状態が変更されたら`isAuthenticated`を更新

2. 画面切り替え:
   - `isAuthenticated == true` → `ChatView`を表示
   - `isAuthenticated == false` → `LoginView`を表示

**実装方法の選択肢**:
- 方法A: `@State`と`onAppear`を使用
- 方法B: 専用の`AuthViewModel`を作成（より拡張性が高い）

### Step 5: エラーハンドリング

#### 5.1. エラー表示方法

**確認事項**: [要確認] エラー表示の方法
- アラート（`alert`モディファイア）
- トースト風の表示
- インライン表示

#### 5.2. 実装すべきエラーケース

1. ログインエラー:
   - メールアドレス/パスワードが間違っている
   - ネットワークエラー
   - その他の認証エラー

2. メッセージ送信エラー:
   - ネットワークエラー
   - 認証エラー（セッション切れなど）
   - バリデーションエラー（空文字など）

3. データ取得エラー:
   - ネットワークエラー
   - 権限エラー

### Step 6: テストとデバッグ

#### 6.1. 動作確認項目

1. 認証機能:
   - [ ] ログインが正常に動作する
   - [ ] ログイン失敗時にエラーが表示される
   - [ ] ログアウトが正常に動作する（実装する場合）

2. メッセージ機能:
   - [ ] メッセージ一覧がリアルタイムで更新される
   - [ ] メッセージ送信が正常に動作する
   - [ ] 送信後、入力フィールドがクリアされる
   - [ ] WebアプリとiOSアプリ間でデータが同期される

3. UI/UX:
   - [ ] ローディング状態が適切に表示される
   - [ ] エラーメッセージが適切に表示される
   - [ ] スクロールがスムーズに動作する

## 5. 確認が必要な事項

### 5.1. 技術的な確認事項

- [ ] **依存関係管理方法**: Swift Package Manager / CocoaPods どちらを使用するか
- [ ] **Firebase SDKバージョン**: 特定のバージョン指定が必要か
- [ ] **FirebaseFirestoreSwift**: `@DocumentID`と`@ServerTimestamp`を使用する場合、このパッケージが必要

### 5.2. UI/UXの確認事項

- [ ] **デザイン要件**: 特定のデザインガイドラインやカラースキームはあるか
- [ ] **メッセージ表示形式**: チャット形式、カード形式、リスト形式など
- [ ] **エラー表示方法**: アラート、トースト、インライン表示など

### 5.3. 機能要件の確認事項

- [ ] **ログアウト機能**: 実装するかどうか
- [ ] **ユーザー登録機能**: 新規ユーザー登録画面は必要か（現時点ではWebアプリで登録を想定？）
- [ ] **メッセージ削除機能**: 実装するかどうか（現時点では削除不可を想定）

## 6. 実装の優先順位

### Phase 1: 基本機能の実装
1. データモデル（`Message.swift`）
2. ViewModel（`ChatViewModel.swift`）
3. ログイン画面（`LoginView.swift`）
4. チャット画面（`ChatView.swift`）
5. 認証状態管理（`ContentView.swift`の更新）

### Phase 2: エラーハンドリングとUX改善
1. エラーハンドリングの実装
2. ローディング状態の表示
3. UI/UXの改善

### Phase 3: 追加機能（オプション）
1. ログアウト機能
2. ユーザー登録機能
3. メッセージ削除機能
4. プルリフレッシュ機能

## 7. 参考リソース

- [Firebase iOS SDK ドキュメント](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication ドキュメント](https://firebase.google.com/docs/auth/ios/start)
- [Cloud Firestore iOS ドキュメント](https://firebase.google.com/docs/firestore/ios/start)
- [SwiftUI ドキュメント](https://developer.apple.com/documentation/swiftui)

## 8. 注意事項

1. **Firebase設定**: `GoogleService-Info.plist`が正しくプロジェクトに追加されていることを確認
2. **セキュリティルール**: Firestoreのセキュリティルールが適切に設定されていることを確認（`plan.md`のPhase 3を参照）
3. **テスト環境**: 開発中はFirestoreのテストモードを使用し、本番環境ではセキュリティルールを適用
4. **メモリ管理**: リスナーの適切な削除を忘れない（メモリリークの防止）
