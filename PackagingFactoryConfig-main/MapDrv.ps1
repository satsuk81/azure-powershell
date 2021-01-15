cmd.exe /C cmdkey /add:`"eucpackagingstoracc01.file.core.windows.net`" /user:`"Azure\eucpackagingstoracc01`" /pass:`"xQpgowglRCFpjnvOQiNf9J4u9TD5Et5r4DodtnUWhb2IE9kW/Gv4grLliOOb9CbQVubTtxjTYjVBWNpiS+KDww==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\eucpackagingstoracc01.file.core.windows.net\packaging" -Persist
