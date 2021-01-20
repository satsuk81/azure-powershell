cmd.exe /C cmdkey /add:`"eucpackagingstoracc01.file.core.windows.net`" /user:`"Azure\eucpackagingstoracc01`" /pass:`"EuJLfVFG6n3qPOtJEQjPSPL/lmsudS4ty/fmfxEmLOeLaKJTSF9/LPY5U5aHtr2pyQGOTO7sNmxFCVOsRgDSgQ==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\eucpackagingstoracc01.file.core.windows.net\packaging" -Persist
