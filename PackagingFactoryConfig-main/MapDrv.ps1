cmd.exe /C cmdkey /add:`"packagingstoracc.file.core.windows.net`" /user:`"Azure\packagingstoracc`" /pass:`"D0AFRMzg0xzukb4tTaJQcS37nx+EeaE2tPTll1FU5FXOZqDuaLlWzDgBK3BYb+a4ON391VE5BIMWwbURrxFJCA==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\packagingstoracc.file.core.windows.net\packaging" -Persist
