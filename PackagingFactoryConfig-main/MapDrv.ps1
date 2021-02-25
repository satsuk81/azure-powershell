cmd.exe /C cmdkey /add:`"stwleucpackaging02.file.core.windows.net`" /user:`"Azure\stwleucpackaging02`" /pass:`"+w2P2NqhmR+9ZoEJCL4YpUZuVbuxHfZYlxXlUDvJ6GZEnKKfwbi+TYlFtDJZX5Y360R/WNRFD/Squc3m2XUN8A==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging02.file.core.windows.net\packaging" -Persist
