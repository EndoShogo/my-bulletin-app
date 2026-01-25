import os
from flask import Flask, render_template
from dotenv import load_dotenv

# .envファイルから環境変数を読み込む
load_dotenv()

app = Flask(__name__)

def get_firebase_config():
    """
    環境変数からFirebaseの設定を取得し、辞書として返します。
    """
    firebase_config = {
        "apiKey": os.getenv("FIREBASE_API_KEY"),
        "authDomain": os.getenv("FIREBASE_AUTH_DOMAIN"),
        "projectId": os.getenv("FIREBASE_PROJECT_ID"),
        "storageBucket": os.getenv("FIREBASE_STORAGE_BUCKET"),
        "messagingSenderId": os.getenv("FIREBASE_MESSAGING_SENDER_ID"),
        "appId": os.getenv("FIREBASE_APP_ID"),
    }
    # いずれかの設定値が存在しない場合はエラーを発生させる
    if not all(firebase_config.values()):
        raise ValueError("Firebaseの設定に必要な環境変数が不足しています。.envファイルを確認してください。")
    return firebase_config

@app.route('/')
def index():
    """掲示板画面を表示します。"""
    try:
        firebase_config = get_firebase_config()
        return render_template('index.html', firebase_config=firebase_config)
    except ValueError as e:
        return str(e), 500

@app.route('/login')
def login():
    """ログイン画面を表示します。"""
    try:
        firebase_config = get_firebase_config()
        return render_template('login.html', firebase_config=firebase_config)
    except ValueError as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001) # iOSアプリが5000番ポートを使用する可能性を考慮
