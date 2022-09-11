README.md                {#LREADME}
=========
# aom-av1-lavish encoding library (An extended fork of aomenc)

## Building the library and applications {#building-the-library-and-applications}

### Prerequisites {#prerequisites}

 1. [CMake](https://cmake.org). See CMakeLists.txt for the minimum version
    required.
 2. [Git](https://git-scm.com/).
 3. [Perl](https://www.perl.org/).
 4. For x86 targets, [yasm](http://yasm.tortall.net/), which is preferred, or a
    recent version of [nasm](http://www.nasm.us/). If you download yasm with
    the intention to work with Visual Studio, please download win32.exe or
    win64.exe and rename it into yasm.exe. DO NOT download or use vsyasm.exe.
 5. Building the documentation requires
   [doxygen version 1.8.10 or newer](http://doxygen.org).
 6. Emscripten builds require the portable
   [EMSDK](https://kripken.github.io/emscripten-site/index.html).

### Get the code {#get-the-code}
`git clone https://github.com/Clybius/aom-av1-lavish` for the **main branch**, where the main "psy" and configuration changes for aom-av1-lavish can be looked at.

`git clone https://github.com/Clybius/aom-av1-lavish -b Endless_Instability` for the **Endless_Instability branch**, where most unstable / public testing changes go.

`git clone https://github.com/Clybius/aom-av1-lavish -b Endless_Merging` for the **Endless_Merging branch**, where Endless_Instability's changes mixed with current aomenc updates go.

### Viewing the status of uploaded changes {#viewing-the-status-of-uploaded-changes}

To check the status of a change that you uploaded, open
[Github PRs](https://github.com/Clybius/aom-av1-lavish/pulls), sign in, and click Pull Requests.

## Support {#support}

This library is an open source project supported by the general AV1 enthusiast encoder community. Please
please send pull requests, feature requests and general comments on this repository.
Other more miscalleneous discussions, contributions, and talks will be done elsewhere.


## Bug reports {#bug-reports}

Bug reports can be filed in the Alliance for Open Media for general aomenc bugs
[issue tracker](https://bugs.chromium.org/p/aomedia/issues/list).

As for the ones related to aom-av1-lavish changes themselves, the issues tab can be used here on Github.

### Advanced Prerequisites

There are various advanced features that aom-av1-lavish can utilize to further boost encoding quality that can be found in the **full_build-alpha-4** branch.

These include butteraugli-jxl RD analysis(8-bit only currently), VMAF motion QP analysis(utilizing VMAF motion to enhance rate control in motion considerably, especially in lower luma scenarios), future SSIMULACRA2 RD analysis, and perceptual quality driven RD analysis with a strong VMAF motion QP analysis.

For VMAF, you need to either download/install the appropriate VMAF libraries for your OS to directly take advantage of it, either through your package manager on Linux or macOS, or downloading stuff directly on Windows:
https://github.com/Netflix/vmaf

As for those who want to build stuff directly from source like me, this is how I personally do it as an example:
```git clone https://github.com/Netflix/vmaf
cd vmaf/libvmaf && mkdir build && cd build
meson .. --buildtype=release --default-library=both -Db_lto=true -Dc_args="-march=native" -Dcpp_args="-march=native" && ninja
sudo ninja install
cd .. && cd .. && cd .. && clear
```

For butteraugli-jxl analysis as well as future ssimulacra RD uses, you will need to download/install/build the appropriate libjxl libraries to get access to all of the required libraries and tools:
https://github.com/libjxl/libjxl

As for those who want to build stuff directly from source like me, an example can be seen below as to how I do it:
```git clone https://github.com/BlueSwordM/libjxl --recursive
    cd libjxl && mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-O3 -march=native" -DCMAKE_C_FLAGS="-O3 -march=native" -DJPEGXL_ENABLE_PLUGINS=ON -DJPEGXL_ENABLE_DEVTOOLS=ON -#DBUILD_TESTING=OFF -DJPEGXL_WARNINGS_AS_ERRORS=OFF -DJPEGXL_ENABLE_SJPEG=OFF  .. && cmake --build . -- -j$(nproc)
    sudo make install
    cd .. && cd .. && clear
```

#### Note that these build scripts are made for installing on your machine with maximum optimizations. These are not meant for distribution.

Now that everything's been said, enjoy your time here, and happy encoding!
