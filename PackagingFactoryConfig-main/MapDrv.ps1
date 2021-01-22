cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"uxtz0lWKgLP+DUIXvxTXxo65vzkaFjz9k4cu3tizjeynsJxn8uXvFiMEaLE3+nU8GxZpAF05gN3evD1BbmNBfw==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
