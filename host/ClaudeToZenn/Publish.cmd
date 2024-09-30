@echo off
setlocal enabledelayedexpansion

REM UTF-8モードを有効にする
chcp 65001 > nul

REM パラメータのチェック
if "%~1"=="" (
    echo エラー: リポジトリのパスが必要です。
    goto :error
)
if "%~2"=="" (
    echo エラー: 記事のタイトルが必要です。
    goto :error
)
if "%~3"=="" (
    echo エラー: ファイルパスが必要です。
    goto :error
)

set "REPO_PATH=%~1"
set "ARTICLE_TITLE=%~2"
set "FILE_PATH=%~3"

REM リポジトリパスの存在チェック
if not exist "%REPO_PATH%" (
    echo エラー: 指定されたリポジトリのパスが存在しません。
    goto :error
)

REM ファイルの存在チェック
if not exist "%FILE_PATH%" (
    echo エラー: 指定されたファイルが存在しません。
    goto :error
)

REM リポジトリに移動
cd /d "%REPO_PATH%"
if %errorlevel% neq 0 (
    echo エラー: %REPO_PATH% へのディレクトリ変更に失敗しました。
    goto :error
)

REM ファイルの内容を表示
echo 記事の内容:
echo -------------------
powershell -Command "Get-Content -Path '%FILE_PATH%' -Encoding UTF8 | ForEach-Object { Write-Host $_ }"
echo -------------------

REM 記事発行の確認
set /p CONFIRM_PUBLISH="上記の内容で記事を発行しますか？ (Y/N): "
if /i not "%CONFIRM_PUBLISH%"=="Y" (
    echo 記事の発行をキャンセルしました。ファイルを削除します。
    del /f "%FILE_PATH%"
    if %errorlevel% neq 0 (
        echo エラー: ファイルの削除に失敗しました。
        goto :error
    )
    echo ファイルが正常に削除されました。
    goto :end
)

REM Git操作の実行
echo 最新の変更を取得中...
git pull
if %errorlevel% neq 0 (
    echo エラー: Git pull に失敗しました。
    goto :error
)

echo 記事を追加中...
git add "%FILE_PATH%"
if %errorlevel% neq 0 (
    echo エラー: Git add に失敗しました。
    goto :error
)

echo 記事を発行中...
git commit -m "記事を発行: %ARTICLE_TITLE%"
if %errorlevel% neq 0 (
    echo エラー: 記事の発行（Git commit）に失敗しました。
    goto :error
)

echo 変更をプッシュ中...
git push
if %errorlevel% neq 0 (
    echo エラー: Git push に失敗しました。
    goto :error
)

echo 記事が正常に発行されました。
goto :end

:error
echo 処理中にエラーが発生しました。

:end
pause
exit /b