# Cygwin auto get install

Cygwinのインストールを自動化します。

# Features
- 以下を自動化します :
  - Cygwinを公式サイトからダウンロードする
  - Cygwinをカレントディレクトリ配下にインストールする
    - レジストリやシステム環境変数に影響を与えません
    - 任意のディレクトリに移動しても動作します
  - Cygwinに(mingw32の)gccとclangをインストールする
  - hello worldをコンパイルして実行する
    - Cygwinがない環境でも動作します（DLLに依存しません）
  - 上記すべてのログを出力する

- 環境を汚さないため、手軽に扱えます。
- コマンドプロンプトからこのコマンドを実行するだけで自動ですべてが完了します。面倒な操作は不要です。
```
curl.exe -L https://raw.githubusercontent.com/cat2151/cygwin-auto-get-install/main/Cygwin_get_and_install.bat --output Cygwin_get_and_install.bat && Cygwin_get_and_install.bat
```

# Requirement
- Windows
- 1.5GB程度の空き容量
- 5分～15分程度の時間（ネットワーク速度により変わります）
- batを実行する場所のフルパス名に半角スペースや日本語を含まないこと

# なぜ名前の構造がmsys2-auto-installと違うの？
既に他の方による同名プロジェクトがありました。区別がつくようにするためです。
