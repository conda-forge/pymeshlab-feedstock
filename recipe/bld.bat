@echo on
setlocal EnableDelayedExpansion

:: ---------------------------------------------------------------------------
:: 1. Configure CMake
:: ---------------------------------------------------------------------------
cmake ^
  -G "Ninja" ^
  -B build ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DCMAKE_INSTALL_PREFIX=%SRC_DIR%/pymeshlab ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DMESHLAB_ALLOW_OPTIONAL_EXTERNAL_LIBRARIES=OFF ^
  -DMESHLAB_BUILD_MINI=OFF ^
  -DCMAKE_INSTALL_LIBDIR=lib

:: ---------------------------------------------------------------------------
:: 2. Build & install
:: ---------------------------------------------------------------------------
cmake --build build --parallel --target install

:: ---------------------------------------------------------------------------
:: 3. Ensure all DLLs end up inside pymeshlab\lib
:: ---------------------------------------------------------------------------
mkdir "%SRC_DIR%\pymeshlab\lib" 2>NUL

if exist "%SRC_DIR%\pymeshlab\PlugIns" (
    for %%F in ("%SRC_DIR%\pymeshlab\PlugIns\*.dll") do (
        copy "%%F" "%SRC_DIR%\pymeshlab\lib\"
    )
)

:: ---------------------------------------------------------------------------
:: 4. Install the Python package into the conda env
:: ---------------------------------------------------------------------------
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation

endlocal
