cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"I6uub3e05oWZ3Aie573xgTt1tk5pVBDYDDPgt4MrASYRs4GzBNaBRpMztb+cJupWKOYOJ2Ac8jiVjcYFmm5Iww==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
