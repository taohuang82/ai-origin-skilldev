@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================================
::  iscit-req2proto Skill 一键安装脚本
::  将 skill 安装到 Cursor 用户空间 (~/.cursor/skills/)
:: ============================================================

set "SKILL_NAME=iscit-req2proto"
set "TARGET_DIR=%USERPROFILE%\.cursor\skills\%SKILL_NAME%"
set "SCRIPT_DIR=%~dp0"

echo.
echo  =============================================
echo    iscit-req2proto Skill 安装程序
echo    供应链需求 → 可交互原型
echo  =============================================
echo.

:: 检查源文件是否存在
if not exist "%SCRIPT_DIR%SKILL.md" (
    echo  [错误] 未找到 SKILL.md，请确认在 iscit-req2proto 目录下运行此脚本
    echo.
    pause
    exit /b 1
)

:: 检查 .cursor 目录
if not exist "%USERPROFILE%\.cursor" (
    echo  [错误] 未找到 %USERPROFILE%\.cursor 目录
    echo          请确认已安装 Cursor 编辑器
    echo.
    pause
    exit /b 1
)

:: 创建 skills 目录（如不存在）
if not exist "%USERPROFILE%\.cursor\skills" (
    mkdir "%USERPROFILE%\.cursor\skills"
    echo  [信息] 已创建 skills 目录
)

:: 如果已安装，询问是否覆盖
if exist "%TARGET_DIR%\SKILL.md" (
    echo  [提示] 检测到已安装的 %SKILL_NAME%
    echo.
    set /p "OVERWRITE=  是否覆盖安装？(Y/N): "
    if /i not "!OVERWRITE!"=="Y" (
        echo.
        echo  已取消安装。
        pause
        exit /b 0
    )
    echo.
    echo  [信息] 正在清理旧版本...
    rmdir /s /q "%TARGET_DIR%"
)

:: 创建目标目录结构
echo  [1/4] 创建目录结构...
mkdir "%TARGET_DIR%" 2>nul
mkdir "%TARGET_DIR%\assets" 2>nul
mkdir "%TARGET_DIR%\references" 2>nul
mkdir "%TARGET_DIR%\scripts" 2>nul

:: 复制文件
echo  [2/4] 复制 Skill 核心文件...
copy /y "%SCRIPT_DIR%SKILL.md" "%TARGET_DIR%\SKILL.md" >nul

echo  [3/4] 复制模板与参考资料...
copy /y "%SCRIPT_DIR%assets\template-tp.html" "%TARGET_DIR%\assets\template-tp.html" >nul
copy /y "%SCRIPT_DIR%assets\template-ap.html" "%TARGET_DIR%\assets\template-ap.html" >nul
copy /y "%SCRIPT_DIR%references\tinyvue-spec.md" "%TARGET_DIR%\references\tinyvue-spec.md" >nul
copy /y "%SCRIPT_DIR%references\isc-scenarios.md" "%TARGET_DIR%\references\isc-scenarios.md" >nul

echo  [4/4] 复制工具脚本...
copy /y "%SCRIPT_DIR%scripts\open_preview.py" "%TARGET_DIR%\scripts\open_preview.py" >nul

:: 验证安装
echo.
set "INSTALL_OK=1"
if not exist "%TARGET_DIR%\SKILL.md"                    set "INSTALL_OK=0"
if not exist "%TARGET_DIR%\assets\template-tp.html"     set "INSTALL_OK=0"
if not exist "%TARGET_DIR%\assets\template-ap.html"     set "INSTALL_OK=0"
if not exist "%TARGET_DIR%\references\tinyvue-spec.md"  set "INSTALL_OK=0"
if not exist "%TARGET_DIR%\references\isc-scenarios.md" set "INSTALL_OK=0"
if not exist "%TARGET_DIR%\scripts\open_preview.py"     set "INSTALL_OK=0"

if "%INSTALL_OK%"=="1" (
    echo  =============================================
    echo    安装成功！
    echo  =============================================
    echo.
    echo  安装位置: %TARGET_DIR%
    echo.
    echo  使用方法:
    echo  重启Cursor后，在对话框中描述您的供应链页面需求即可。
    echo.
) else (
    echo  [错误] 安装验证失败，部分文件未正确复制
    echo          请检查磁盘空间和文件权限后重试
    echo.
)

pause
