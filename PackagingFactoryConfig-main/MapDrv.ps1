cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"teoOM+fg+cUBzINRLcuK95t58lzqxdqBxj+XyohA35gAImz06vSMZ+SlE5+SZ4B3faczPFRsvtvLGGExK3/4QA==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
