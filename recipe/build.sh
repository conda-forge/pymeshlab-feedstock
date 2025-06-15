#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 0. DYNAMICALLY FIND DEPENDENCY PATHS
###############################################################################

# Find the embree cmake directory
EMBREE_CMAKE_DIRS=( "${PREFIX}"/lib/cmake/embree-*/ )
if [ ${#EMBREE_CMAKE_DIRS[@]} -ne 1 ]; then
  echo "Error: Found zero or more than one embree cmake directory." >&2
  exit 1
fi
EMBREE_CMAKE_DIR="${EMBREE_CMAKE_DIRS[0]%/}"

# Find the TBB cmake directory
TBB_CMAKE_DIRS=( "${PREFIX}"/lib/cmake/TBB/ )
if [ ${#TBB_CMAKE_DIRS[@]} -ne 1 ]; then
  echo "Error: Found zero or more than one TBB cmake directory." >&2
  exit 1
fi
TBB_CMAKE_DIR="${TBB_CMAKE_DIRS[0]%/}"

###############################################################################
# 1. Configure CMake
###############################################################################
cmake_args=(
  -G Ninja
  -B build
  -DBUILD_SHARED_LIBS=OFF
  -DCMAKE_INSTALL_PREFIX="${SRC_DIR}/pymeshlab"
  -DCMAKE_BUILD_TYPE=Release
  -Dembree_DIR="${EMBREE_CMAKE_DIR}"
  -DTBB_DIR="${TBB_CMAKE_DIR}"
  -DMESHLAB_ALLOW_OPTIONAL_EXTERNAL_LIBRARIES=ON
  -DMESHLAB_ALLOW_DOWNLOAD_SOURCE_LIBE57=OFF
  -DMESHLAB_ALLOW_DOWNLOAD_SOURCE_U3D=OFF
  -DMESHLAB_BUILD_MINI=OFF
)

# --- macOS quirk -------------------------------------------------------------
# MeshLab’s CMake files install .dylib and plug-in .so files into
#   Frameworks/ and PlugIns/  instead of lib/.
# For conda-build we want everything under lib/ so the usual rsync step works.
if [[ "${target_platform}" == osx-* ]]; then
  cmake_args+=(-DCMAKE_INSTALL_LIBDIR=lib)     # ask CMake to use lib/
fi
# -----------------------------------------------------------------------------

cmake "${cmake_args[@]}" "${SRC_DIR}"
cmake --build build --parallel --target install

###############################################################################
# 2. macOS: gather libraries into pymeshlab/lib/ if CMake still put them elsewhere
###############################################################################
if [[ "${target_platform}" == osx-* ]]; then
  mkdir -p "${SRC_DIR}/pymeshlab/lib"

  # Copy Frameworks/*.dylib and PlugIns/*.so only if they exist
  cp -a "${SRC_DIR}/pymeshlab/Frameworks/"*.dylib "${SRC_DIR}/pymeshlab/lib/" 2>/dev/null || true
  cp -a "${SRC_DIR}/pymeshlab/PlugIns/"*.so    "${SRC_DIR}/pymeshlab/lib/" 2>/dev/null || true
fi

###############################################################################
# 3. Copy the collected libraries into $PREFIX/lib
###############################################################################
rsync -avm --include="*${SHLIB_EXT}" --include="*/" --exclude="*" \
      "${SRC_DIR}/pymeshlab/lib/" "${PREFIX}/lib/"

###############################################################################
# 4. Install the Python wheel into the conda environment
###############################################################################
"${PYTHON}" -m pip install . -vv --no-deps --no-build-isolation
