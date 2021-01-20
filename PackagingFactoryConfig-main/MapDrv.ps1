cmd.exe /C cmdkey /add:`"eucpackagingstoracc01.file.core.windows.net`" /user:`"Azure\eucpackagingstoracc01`" /pass:`"qvBB+sPWzGgS4dC8+KqEmnUEVfleRpU1hSEI8PthL4jsUgI1Yere1ZMWqLy/c6OaYbSJQXXCRSf4LGwqcpBf4A==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\eucpackagingstoracc01.file.core.windows.net\packaging" -Persist
