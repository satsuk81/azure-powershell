cmd.exe /C cmdkey /add:`"stwleucpackaging02.file.core.windows.net`" /user:`"Azure\stwleucpackaging02`" /pass:`"Lhfp47mmj523pZi/tu/P9r8X/7HLotsh8dMu359lteMtS76FCASFziaC1KF4WUVMG6lHD/DmOgszkR3EqW/XkQ==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\stwleucpackaging02.file.core.windows.net\packaging" -Persist
