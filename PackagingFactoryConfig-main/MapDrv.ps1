cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"HdSEzc4PfOrqQpdW8OIXzni+50JeqtNrqkKDT8wj7/slp08Cu+OjRwu42YH1PlS2l/v8LczRB0CcZJFYlcekZg==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
