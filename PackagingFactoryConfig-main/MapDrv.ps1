cmd.exe /C cmdkey /add:`"packagingstoracc.file.core.windows.net`" /user:`"Azure\packagingstoracc`" /pass:`"n9oL4E06xHy4THbiwHPwx2qfWAaYRGPbuWppzFdczqOZ9WSaV3qSTyocNMHPPB4H5RgYae7wT6ltG/ghiSIhow==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\packagingstoracc.file.core.windows.net\packaging" -Persist
