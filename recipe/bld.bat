@echo on
::======================================================================
:: PyMeshLab – Windows build script for conda-forge
::======================================================================

setlocal EnableDelayedExpansion

::----------------------------------------------------------------------
:: 1. Configure CMake
::----------------------------------------------------------------------
cmake ^
  -G "Ninja" ^
  -B build ^
  -S "%SRC_DIR%" ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DCMAKE_INSTALL_PREFIX="%SRC_DIR%\pymeshlab" ^
  -DCMAKE_INSTALL_LIBDIR=lib ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DMESHLAB_ALLOW_OPTIONAL_EXTERNAL_LIBRARIES=OFF ^
  -DMESHLAB_BUILD_MINI=OFF

::----------------------------------------------------------------------
:: 2. Build & install
::----------------------------------------------------------------------
cmake --build build --target install --parallel

::----------------------------------------------------------------------
:: 3. Collect every DLL (and PYD) under a single directory
::    so the recipe’s post-processing can copy them to %PREFIX%\lib
::----------------------------------------------------------------------
mkdir "%SRC_DIR%\pymeshlab\lib" 2>NUL

:: copy plug-ins (*.dll) into lib\
if exist "%SRC_DIR%\pymeshlab\PlugIns" (
    for %%F in ("%SRC_DIR%\pymeshlab\PlugIns\*.dll") do (
        copy "%%F" "%SRC_DIR%\pymeshlab\lib\"  >NUL
    )
)

:: copy helper DLLs / PYDs from the package root into lib\
for %%F in ("%SRC_DIR%\pymeshlab\*.dll") do copy "%%F" "%SRC_DIR%\pymeshlab\lib\"  >NUL
for %%F in ("%SRC_DIR%\pymeshlab\*.pyd") do copy "%%F" "%SRC_DIR%\pymeshlab\lib\"  >NUL

::----------------------------------------------------------------------
:: 3½.  **Fix over-linking** – duplicate helper DLLs next to each plug-in
::       so $RPATH/meshlab-common.dll and $RPATH/external-glew.dll resolve.
::----------------------------------------------------------------------
if exist "%SRC_DIR%\pymeshlab\PlugIns" (
    for %%H in (meshlab-common.dll meshlab-common-gui.dll external-glew.dll) do (
        if exist "%SRC_DIR%\pymeshlab\%%H" (
            copy "%SRC_DIR%\pymeshlab\%%H" "%SRC_DIR%\pymeshlab\PlugIns\" >NUL
        )
    )
)

::----------------------------------------------------------------------
:: 4. Install the Python wheel into the active conda environment
::----------------------------------------------------------------------
%PYTHON% -m pip install "%SRC_DIR%" -vv --no-deps --no-build-isolation

endlocal
