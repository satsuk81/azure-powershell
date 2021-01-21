cmd.exe /C cmdkey /add:`"eucpackagingstoracc01.file.core.windows.net`" /user:`"Azure\eucpackagingstoracc01`" /pass:`"GUiAVTi5OvEdlhmmd3C/eG3qRnQ2FWdQrnsw/5DiAdE7UZdptg6lp4mXPM+sldmyh+gJwIGjIQc7CsoPrF+VgA==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\eucpackagingstoracc01.file.core.windows.net\packaging" -Persist
