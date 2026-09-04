@echo off
title SYED SADIQ POLY CLINIC & HOSPITAL - SOFTWARE LAUNCHER
color 0A
cls
echo =======================================================================
echo     SYED SADIQ POLY CLINIC & HOSPITAL MANAGEMENT SYSTEM (OFFLINE)
echo =======================================================================
echo.
echo [1/2] Starting Offline Local Server for Windows 7 / 8 / 10 / 11...
echo [2/2] Opening Web Browser...
echo.
echo IMPORTANT: Keep this window open while using the software.
echo You can minimize this window to the taskbar.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$PSScriptRoot = '%~dp0'.TrimEnd('\'); $port=8080; $listener = New-Object System.Net.HttpListener; $listener.Prefixes.Add('http://localhost:' + $port + '/'); try { $listener.Start() } catch { $port=8089; $listener = New-Object System.Net.HttpListener; $listener.Prefixes.Add('http://localhost:' + $port + '/'); $listener.Start() }; Write-Host ('[SUCCESS] Software Server active on http://localhost:' + $port); Start-Process ('http://localhost:' + $port + '/'); while ($listener.IsListening) { try { $context = $listener.GetContext(); $req = $context.Request; $res = $context.Response; $path = $req.Url.LocalPath; if ($path -eq '/' -or [string]::IsNullOrWhiteSpace($path)) { $path = '/index.html' }; $filePath = [System.IO.Path]::Combine($PSScriptRoot, $path.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)); if ([System.IO.File]::Exists($filePath)) { $bytes = [System.IO.File]::ReadAllBytes($filePath); $ext = [System.IO.Path]::GetExtension($filePath).ToLower(); switch ($ext) { '.html' { $res.ContentType = 'text/html; charset=utf-8' } '.js' { $res.ContentType = 'application/javascript' } '.css' { $res.ContentType = 'text/css' } '.json' { $res.ContentType = 'application/json' } '.png' { $res.ContentType = 'image/png' } '.otf' { $res.ContentType = 'font/otf' } '.ttf' { $res.ContentType = 'font/ttf' } '.wasm' { $res.ContentType = 'application/wasm' } default { $res.ContentType = 'application/octet-stream' } }; $res.ContentLength64 = $bytes.Length; $res.OutputStream.Write($bytes, 0, $bytes.Length) } else { $res.StatusCode = 404 }; $res.OutputStream.Close() } catch {} }"

pause

