cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"dq+6aXROPqFqkeAI95XUTLrdLCqnJwTPKACAnQZPAoyUjYYluwBJFJrFYbknI0U0GafwJPACQJ84zyg2CXE/Lg==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
