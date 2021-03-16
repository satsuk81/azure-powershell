cmd.exe /C cmdkey /add:`"wlprodeusprodpkgstr01.file.core.windows.net`" /user:`"Azure\wlprodeusprodpkgstr01`" /pass:`"s9joA/NOc94meybF/lasFWDB55fFx3JP0OEYddtYljpRswpjErowqz9wXZe2zVY1/CW1Aujle3ED1fEJtnsEvg==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\wlprodeusprodpkgstr01.file.core.windows.net\pkgazfiles01" -Persist
