@echo on

setlocal EnableDelayedExpansion

cmake -S "%SRC_DIR%" -B build -G "Ninja" ^
      -DBUILD_SHARED_LIBS=OFF ^
      -DCMAKE_INSTALL_PREFIX="%SRC_DIR%\pymeshlab" ^
      -DCMAKE_INSTALL_LIBDIR=lib ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DMESHLAB_ALLOW_OPTIONAL_EXTERNAL_LIBRARIES=OFF ^
      -DMESHLAB_BUILD_MINI=OFF

cmake --build build --target install --parallel %CPU_COUNT%

:: copy helper DLLs so plug-ins find them at runtime
for %%H in (meshlab-common.dll meshlab-common-gui.dll external-glew.dll) do (
    if exist "%SRC_DIR%\pymeshlab\%%H" (
        copy /Y "%SRC_DIR%\pymeshlab\%%H" "%SRC_DIR%\pymeshlab\PlugIns\" >NUL
    )
)

:: gather all binaries under lib/
mkdir "%SRC_DIR%\pymeshlab\lib" 2>NUL
for %%F in ("%SRC_DIR%\pymeshlab\*.dll" "%SRC_DIR%\pymeshlab\*.pyd" ^
            "%SRC_DIR%\pymeshlab\PlugIns\*.dll") do (
    copy /Y "%%~F" "%SRC_DIR%\pymeshlab\lib\" >NUL
)

%PYTHON% -m pip install "%SRC_DIR%" -vv --no-deps --no-build-isolation

endlocal
