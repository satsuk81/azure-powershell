cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"7UV/Ua92SSxof348MsuKU/5boCRxynw6qOEgZV3TNp+ZV9SfIuDkxDVtNQJbavLqHni01Ws/qZIbFQ2q9JwdqA==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
