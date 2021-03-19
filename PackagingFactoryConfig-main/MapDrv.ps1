cmd.exe /C cmdkey /add:`"wlprodeusprodpkgstr01.file.core.windows.net`" /user:`"Azure\wlprodeusprodpkgstr01`" /pass:`"rg-wl-prod-packaging`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\wlprodeusprodpkgstr01.file.core.windows.net\pkgazfiles01" -Persist
