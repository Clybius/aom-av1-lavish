#!/bin/bash

# Build script for aom-lavish
# Builds the Endless_Merging branch and all patches inside ./patches

error() { echo -e "\033[31mERROR: $@\033[0m"; exit 1; }
warn() { echo -e "\033[33mWARNING: $@\033[0m"; }
success() { echo -e "\033[32mSUCCESS: $@\033[0m"; }
info() { echo -e "\033[34mINFO: $@\033[0m"; }

main() {
  local butteraugli=0
  local vmaf=0

  local optimize=''
  local static=''
  local jobs=$(nproc)

  local shared_libs=0
  local tests=0
  local docs=0

  check_deps make gcc cmake nasm yasm vim pkgconf
  echo

  while [[ "$#" -gt 0 ]]; do
    key="$1"
    case "$1" in
      -h|--help)
        echo
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  -v, --vmaf           Enable VMAF support"
        echo "  -b, --butteraugli    Enable Butteraugli support"
        echo "  -l, --shared-libs    Enable shared libraries"
        echo "  -t, --tests          Enable tests building"
        echo "  -d, --docs           Enable documentation building"
        echo "  -o, --optimize       Enable optimizations (-Ofast -flto -march=native)"
        echo "  -s, --static         Enable static linking"
        echo "  -j, --jobs <num>     Specify the number of jobs"
        echo "  -h, --help           Show this help message and exit"
        echo
        exit 0
        ;;
      -v|--vmaf) vmaf=1; check_deps vmaf; info 'Building with VMAF support...'; shift;;
      -b|--butteraugli) butteraugli=1; info 'Building with Butteraugli support...'
         warn "libjxl needs to be compiled and installed with commit '4e4f49c57f165809a75ccd12d2ce5c060963aa01' for butteraugli support"
         check_deps libjxl; shift;;
      -l|--shared-libs) shared_libs=1; info 'Building shared libs...'; shift;;
      -t|--tests) tests=1; info 'Building tests...' shift;;
      -d|--docs) docs=1; check_deps doxygen; info 'Building docs...' shift;;
      -o|--optimize) optimize='-Ofast -flto -march=native'; info 'Building with optimization flags...'; shift;;
      -s|--static) static='-static'; info 'Building a static binary...'; shift;;
      -j|--jobs) jobs="$2"; shift; shift;;
      *) error "Unknown option: $key";;
    esac
  done

  info "Building with $jobs jobs..."
  readarray -t repo_files <<< $(ls -a1 | tail -n+3 | grep -ve 'build-' -e "${0##*/}" -e 'repo.tar' -e '.git')
  configure="cmake .. -DENABLE_DOCS=$docs -DENABLE_TESTS=$tests -DBUILD_SHARED_LIBS=$shared_libs -DCONFIG_TUNE_VMAF=$vmaf -DCONFIG_TUNE_BUTTERAUGLI=$butteraugli"
  build="make -j$jobs"

  build_component 'lavish'
  mv build build-lavish
  mkdir -p build
  cp -r build-lavish/cmake build

  # Using tar because using git revert after git apply breaks
  for patch in patches/*.patch; do
    rm -f repo.tar
    tar cf repo.tar "${repo_files[@]}"

    basename="${patch##*/}"
    custom_dir="build-${basename%.*}-patch"

    git apply "$patch" || error "Failed to apply patch $patch"
    build_component "$patch"

    rm -rf "$custom_dir"
    mv build "$custom_dir"
    mkdir build
    cp -r "$custom_dir/cmake" build

    rm -rf "${repo_files[@]}"
    tar xf repo.tar
  done
}

build_component() {
  local path="$PWD"
  local name="${1//-/ }"; name="${name//_/ }"
        name="${name##*/}"; name="${name%.*}"
  local build_dir="build"

  if [ -d "$build_dir/cmake" ]; then
    mv "$build_dir/cmake" "cmake-tmp"
    rm -rf "$build_dir" 2>/dev/null
    mkdir -p "$build_dir"
    mv "cmake-tmp" "$build_dir/cmake"
  fi

  echo; info "Building $name"
  cd "$build_dir"
  if [ -n "$configure" ]; then
    echo -e "\n\e[35m$configure -DCMAKE_CXX_FLAGS='$optimize $static' -DCMAKE_C_FLAGS='$optimize $static'\e[0m\n"
    $configure -DCMAKE_CXX_FLAGS="$optimize $static" -DCMAKE_C_FLAGS="$optimize $static" \
    || error "Failed to configure $name"
  fi
  if [ -n "$build" ]; then
    echo -e "\n\e[35m$build\e[0m\n"
    $build || error "Failed to build $name"
  fi
  cd "$path"
  success "Built $name"
}

check_deps() {
  if [ -z "$packages" ]; then
    if [ -f /bin/dpkg-query ]; then
      readarray -t packages <<< $(dpkg-query -W -f='${Package}\n')
    elif [ -f /bin/pacman ]; then
      readarray -t packages <<< $(pacman -Qq)
    else
      warn "The system does not have dpkg or pacman intalled, proceeding without dependency checks."
      return
    fi
  fi

  unset missing
  for dependency in "$@"; do
    unset found
    for package in "${packages[@]}"; do
      [ "$package" = "$dependency" ] && found=true
    done
    [ -z "$found" ] && missing+=("$dependency")
  done

  [ -n "$missing" ] && error "Missing dependencies: ${missing[@]}"
}

main "$@"
