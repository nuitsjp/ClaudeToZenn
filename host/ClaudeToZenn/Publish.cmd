@echo off
setlocal enabledelayedexpansion

REM �p�����[�^�̃`�F�b�N
if "%~1"=="" (
    echo Error: Repository path is required.
    goto :error
)
if "%~2"=="" (
    echo Error: Commit message is required.
    goto :error
)

set "REPO_PATH=%~1"
set "COMMIT_MSG=%~2"

REM ���|�W�g���p�X�̑��݃`�F�b�N
if not exist "%REPO_PATH%" (
    echo Error: The specified repository path does not exist.
    goto :error
)

REM ���|�W�g���Ɉړ�
cd /d "%REPO_PATH%"
if %errorlevel% neq 0 (
    echo Error: Failed to change directory to %REPO_PATH%
    goto :error
)

REM Git����̎��s
echo Pulling latest changes...
git pull
if %errorlevel% neq 0 (
    echo Error: Git pull failed.
    goto :error
)

echo Adding all changes...
git add .
if %errorlevel% neq 0 (
    echo Error: Git add failed.
    goto :error
)

echo Committing changes...
git commit -m "%COMMIT_MSG%"
if %errorlevel% neq 0 (
    echo Error: Git commit failed.
    goto :error
)

REM Push�̓R�����g�A�E�g
REM echo Pushing changes...
REM git push
REM if %errorlevel% neq 0 (
REM     echo Error: Git push failed.
REM     goto :error
REM )

echo All operations completed successfully.
goto :end

:error
echo An error occurred during the process.

:end
pause
exit /b