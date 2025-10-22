@echo off
REM ==========================================
REM 启动本地 Jekyll 博客预览
REM 作者: Sen Liao
REM ==========================================

REM 设置目标路径（请确保这个路径正确）
set BLOG_PATH=D:\Onedrive\02_Work\00_正式工作\00_H3C_Network Engineer\技术blog\sen-ls.github.io

REM 进入博客目录
cd /d "%BLOG_PATH%"

REM 检查 Ruby 是否安装
ruby -v >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Ruby 环境，请先安装 Ruby+DevKit！
    pause
    exit /b
)

REM 检查 Bundler 是否安装
bundle -v >nul 2>&1
if errorlevel 1 (
    echo [错误] Bundler 未安装，请运行: gem install bundler
    pause
    exit /b
)

echo ==========================================
echo 正在启动本地 Jekyll 服务器...
echo 网站地址: http://127.0.0.1:4000/
echo ==========================================

REM 启动服务器
start "" http://127.0.0.1:4000/
bundle exec jekyll serve

pause
