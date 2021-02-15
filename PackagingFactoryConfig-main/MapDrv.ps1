cmd.exe /C cmdkey /add:`"stwleucpackaging01.file.core.windows.net`" /user:`"Azure\stwleucpackaging01`" /pass:`"gO0EnE2pG/CGSO/9kUx76Bea+Ffbd6amFYwl4qyAVaYNYS08Spak6So42LJ2gs++6MBmU10JfbAkQsFUd2V51w==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging01.file.core.windows.net\packaging" -Persist
