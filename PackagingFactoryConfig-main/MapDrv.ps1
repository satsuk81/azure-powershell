cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"xjvZrmoumq910UCPmNlMcEtwwWk9mHqXmJCaf9/Rpi4mI4yFLaartynAUHOWk7QSzstz7eFLCZkVilNChUHufw==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
