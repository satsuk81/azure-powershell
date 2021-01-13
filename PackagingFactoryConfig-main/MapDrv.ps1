cmd.exe /C cmdkey /add:`"packagingstoracc.file.core.windows.net`" /user:`"Azure\packagingstoracc`" /pass:`"nbO/Re3BLDWmWxuP6kxKUcv8HZbpRNC1EBvGftlOIcbSKmGjslqxeNF+Pz1zJwFK6YIwzftj7qXVIcsnMJm6Sg==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\packagingstoracc.file.core.windows.net\packaging" -Persist
