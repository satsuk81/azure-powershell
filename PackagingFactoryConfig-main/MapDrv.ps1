cmd.exe /C cmdkey /add:`"packagingstoracc.file.core.windows.net`" /user:`"Azure\packagingstoracc`" /pass:`"fnF/V7YS8u1Qjwr6LKXlf830RDFoBCSOW0VU85B57C5M+c+xlcpojHltnJMQzzjpOF/0VEzQQdSmqrLBQ+qqKQ==`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\packagingstoracc.file.core.windows.net\packaging" -Persist
