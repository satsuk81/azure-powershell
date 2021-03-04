cmd.exe /C cmdkey /add:`"wlprodeusprodpkgstr01tmp.file.core.windows.net`" /user:`"Azure\wlprodeusprodpkgstr01tmp`" /pass:`"rg-wl-prod-packaging`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\wlprodeusprodpkgstr01tmp.file.core.windows.net\packaging" -Persist
