
Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "F:\blog"
WshShell.Run "C:\nvm4w\nodejs\pnpm.cmd dev", 0, False
