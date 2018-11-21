SET IZON_PS1=https://raw.githubusercontent.com/PredixDev/izon/master/izon.ps1
CALL :%*
EXIT /b !errorlevel!

:READ_DEPENDENCY
  IF EXIST "%4\version.json" (
    IF NOT [%4]==[%TEMP%] COPY /Y "%4\version.json" "%TEMP%"

    SET URL=
    SET TAG=

    powershell -Command "(new-object net.webclient).DownloadFile('%IZON_PS1%','%TEMP%\izon.ps1')"
    FOR /F %%d IN ('powershell -Command "[System.IO.File]::ReadAllText(\"$Env:TEMP\izon.ps1\") | iex; ReadDependency-Izon(\"%1\")"') DO (
        IF DEFINED URL SET TAG=%%d
        IF NOT DEFINED URL SET URL=%%d
    )

    SET %2=!URL!
    SET %3=!TAG!
  ) ELSE (
    ECHO Unable to find version.json file
    EXIT /b 1
  )
GOTO :eof
