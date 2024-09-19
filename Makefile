# Specify "make PLATFORM=<platform>" to compile for a specific target.
# Check the supported list of platforms below for a full list

#
## Optional parameters
## Uncomment these to enable them, or specify them from the command line
## For example: "make PLATFORM=<xyz> -DDEBUG=1" will enable Debug builds
#

# Create Debug build, instead of Release one
#DEBUG=1

# Profiler options
#GCC_PROFILE=1
#GEN_PROFILE=1
#USE_PROFILE=1

# Enable LTO
#USE_LTO=1

# Memory Sanitizer
#SANITIZE=1

# Use GPIOD to control the GPIO pins, on a device that has them (e.g. Raspberry Pi)
# This allows the use of certain pins as external LEDs for activity
#USE_GPIOD=1

# Experimental OpenGL(ES) target
# Note: the GUI cannot render TTF fonts when this option is enabled, so it will use
# a bitmap font instead (included in the data directory)
#USE_OPENGL=1

# Use DBUS features, to control Amiberry functions from another application
#USE_DBUS=1

# Compile on a version of GCC older than 8.0
#USE_OLDGCC=1

#
## Common options for all targets
#
SDL_CONFIG ?= sdl2-config
export SDL_CFLAGS := $(shell $(SDL_CONFIG) --cflags)
export SDL_LDFLAGS := $(shell $(SDL_CONFIG) --libs)

CPPFLAGS = -MD -MT $@ -MF $(@:%.o=%.d) $(SDL_CFLAGS) -Iexternal/libguisan/include -Isrc -Isrc/osdep -Isrc/threaddep -Isrc/include -Isrc/archivers -Isrc/ppc/pearpc -Iexternal/floppybridge/src -Iexternal/mt32emu/src -D_FILE_OFFSET_BITS=64
CFLAGS=-pipe -Wno-shift-overflow -Wno-narrowing -fno-pie

LDFLAGS = $(SDL_LDFLAGS) -lSDL2_image -lSDL2_ttf -lserialport -lportmidi -lguisan -Lexternal/libguisan/lib -lmt32emu -Lexternal/mt32emu
LDFLAGS += -Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -lpthread -lz -lpng -lrt -lFLAC -lmpg123 -ldl -lmpeg2convert -lmpeg2 -lstdc++fs -no-pie

ifdef USE_OPENGL
	CFLAGS += -DUSE_OPENGL
	LDFLAGS += -lGLEW -lGL
endif

ifdef USE_LTO
	CFLAGS += -flto
	LDFLAGS += -flto
endif

# Use libgpiod to control GPIO LEDs?
ifdef USE_GPIOD
	CFLAGS += -DUSE_GPIOD
	LDFLAGS += -lgpiod
endif

# Use DBUS to control the emulator?
ifdef USE_DBUS
	DBUS_CFLAGS := $(shell pkg-config dbus-1 --cflags)
	DBUS_LIBS := $(shell pkg-config dbus-1 --libs)
	CFLAGS += $(DBUS_CFLAGS) -DUSE_DBUS
	LDFLAGS += $(DBUS_LIBS)
endif

ifndef DEBUG
	CFLAGS += -O3
else
	CFLAGS += -g -rdynamic -funwind-tables -DDEBUG -Wl,--export-dynamic
endif

ifdef USE_OLDGCC
	CFLAGS += -DUSE_OLDGCC
endif

#Common flags for all 32bit targets
CPPFLAGS32=-DARMV6T2

#Common flags for all 64bit targets
CPPFLAGS64=-DCPU_AARCH64

#Neon flags
NEON_FLAGS=-DARM_HAS_DIV

# Raspberry Pi 2 CPU flags
ifneq (,$(findstring rpi2,$(PLATFORM)))
	CPUFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4
endif

# Raspberry Pi 3 CPU flags
ifneq (,$(findstring rpi3,$(PLATFORM)))
	CPUFLAGS = -mcpu=cortex-a53 -mfpu=neon-fp-armv8
endif

# Raspberry Pi 4 CPU flags
ifneq (,$(findstring rpi4,$(PLATFORM)))
	CPUFLAGS = -mcpu=cortex-a72 -mfpu=neon-fp-armv8
endif

# Raspberry 5 CPU flags
ifneq (,$(findstring rpi5,$(PLATFORM)))
     CPUFLAGS = -mcpu=cortex-a76 -mfpu=neon-fp-armv8
endif

# MacOS Apple Silicon CPU flags
ifneq (,$(findstring osx-m1,$(PLATFORM)))
	CPUFLAGS=-mcpu=apple-m1
endif

#
# SDL2 targets
#
# Raspberry Pi 2/3/4/5 (SDL2)
ifeq ($(PLATFORM),$(filter $(PLATFORM),rpi2-sdl2 rpi3-sdl2 rpi4-sdl2 rpi5-sdl2))
	CPPFLAGS += $(CPPFLAGS32)
	CPPFLAGS += $(NEON_FLAGS)
	HAVE_NEON = 1

# OrangePi (SDL2)
else ifeq ($(PLATFORM),orangepi-pc)
	CPUFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1
	ifdef DEBUG
		# Otherwise we'll get compilation errors, check https://tls.mbed.org/kb/development/arm-thumb-error-r7-cannot-be-used-in-asm-here
		# quote: The assembly code in bn_mul.h is optimized for the ARM platform and uses some registers, including r7 to efficiently do an operation. GCC also uses r7 as the frame pointer under ARM Thumb assembly.
		CFLAGS += -fomit-frame-pointer
	endif

# OrangePi Zero (SDL2)
else ifeq ($(PLATFORM),orangepi-zero)
	CPUFLAGS = -mcpu=cortex-a53
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1
	ifdef DEBUG
		# Otherwise we'll get compilation errors, check https://tls.mbed.org/kb/development/arm-thumb-error-r7-cannot-be-used-in-asm-here
		# quote: The assembly code in bn_mul.h is optimized for the ARM platform and uses some registers, including r7 to efficiently do an operation. GCC also uses r7 as the frame pointer under ARM Thumb assembly.
		CFLAGS += -fomit-frame-pointer
	endif

# Odroid XU4 (SDL2)
else ifeq ($(PLATFORM),xu4)
	CPUFLAGS = -mcpu=cortex-a15 -mfpu=neon-vfpv4
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1
	ifdef DEBUG
		# Otherwise we'll get compilation errors, check https://tls.mbed.org/kb/development/arm-thumb-error-r7-cannot-be-used-in-asm-here
		# quote: The assembly code in bn_mul.h is optimized for the ARM platform and uses some registers, including r7 to efficiently do an operation. GCC also uses r7 as the frame pointer under ARM Thumb assembly.
		CFLAGS += -fomit-frame-pointer
	endif

# Odroid C1 (SDL2)
else ifeq ($(PLATFORM),c1)
	CPUFLAGS = -mcpu=cortex-a5 -mfpu=neon-vfpv4
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1
	ifdef DEBUG
		# Otherwise we'll get compilation errors, check https://tls.mbed.org/kb/development/arm-thumb-error-r7-cannot-be-used-in-asm-here
		# quote: The assembly code in bn_mul.h is optimized for the ARM platform and uses some registers, including r7 to efficiently do an operation. GCC also uses r7 as the frame pointer under ARM Thumb assembly.
		CFLAGS += -fomit-frame-pointer
	endif

# Odroid N1/N2, RockPro64 (SDL2 64-bit)
else ifeq ($(PLATFORM),n2)
	CPUFLAGS = -mcpu=cortex-a72
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Raspberry Pi 3 (SDL2 64-bit)
else ifeq ($(PLATFORM),rpi3-64-sdl2)
	CPUFLAGS = -mcpu=cortex-a53
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Raspberry Pi 4 (SDL2 64-bit)
else ifeq ($(PLATFORM),rpi4-64-sdl2)
	CPUFLAGS = -mcpu=cortex-a72+crc+simd+fp
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Raspberry Pi 4 (SDL2 with OpenGLES 64-bit) - experimental
else ifeq ($(PLATFORM),rpi4-64-opengl)
	CPUFLAGS = -mcpu=cortex-a72+crc+simd+fp
	CPPFLAGS += $(CPPFLAGS64) -DUSE_OPENGL
	LDFLAGS += -lGL
	AARCH64 = 1

# Raspberry Pi 5 (SDL2 64-bit)
else ifeq ($(PLATFORM),rpi5-64-sdl2)
     CPUFLAGS = -mcpu=cortex-a76
     CPPFLAGS += $(CPPFLAGS64)
     AARCH64 = 1

# Vero 4k (SDL2)
else ifeq ($(PLATFORM),vero4k)
	CPUFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
	CFLAGS += -ftree-vectorize -funsafe-math-optimizations
	CPPFLAGS += -I/opt/vero3/include $(CPPFLAGS32) $(NEON_FLAGS)
	LDFLAGS += -L/opt/vero3/lib
	HAVE_NEON = 1

# Amlogic S905/S905X/S912 (AMLGXBB/AMLGXL/AMLGXM) e.g. Khadas VIM1/2 / S905X2 (AMLG12A) & S922X/A311D (AMLG12B) e.g. Khadas VIM3 - 32-bit userspace
else ifneq (,$(findstring AMLG,$(PLATFORM)))
	CPUFLAGS = -mfloat-abi=hard -mfpu=neon-fp-armv8
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1

	ifneq (,$(findstring AMLG12,$(PLATFORM)))
	  ifneq (,$(findstring AMLG12B,$(PLATFORM)))
		CPUFLAGS = -mcpu=cortex-a73
	  else
		CPUFLAGS = -mcpu=cortex-a53
	  endif
	else ifneq (,$(findstring AMLGX,$(PLATFORM)))
	  CPUFLAGS = -mcpu=cortex-a53
	endif

# Amlogic S905D3/S905X3/S905Y3 (AMLSM1) e.g. HardKernel ODroid C4 & Khadas VIM3L (SDL2 64-bit)
else ifneq (,$(findstring AMLSM1,$(PLATFORM)))
	CPUFLAGS = -mcpu=cortex-a55
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Odroid Go Advance target (SDL2, 64-bit)
else ifeq ($(PLATFORM),oga)
	CPUFLAGS = -mcpu=cortex-a35
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# macOS Apple Silicon (SDL2, 64-bit, Apple Silicon)
else ifeq ($(PLATFORM),osx-m1)
	LDFLAGS = -L/usr/local/lib -Lexternal/mt32emu -lSDL2_image -lSDL2_ttf -lpng -liconv -lz -lFLAC -L/opt/homebrew/lib/ -lmpg123 -lmpeg2 -lmpeg2convert -lserialport -lportmidi -lmt32emu $(SDL_LDFLAGS) -framework IOKit -framework Foundation
	CPPFLAGS = -MD -MT $@ -MF $(@:%.o=%.d) $(SDL_CFLAGS) -I/opt/homebrew/include -Iexternal/libguisan/include -Isrc -Isrc/osdep -Isrc/threaddep -Isrc/include -Isrc/archivers -Iexternal/floppybridge/src -Iexternal/mt32emu/src -D_FILE_OFFSET_BITS=64 -DCPU_AARCH64 $(SDL_CFLAGS)
	CXX=/usr/bin/c++
#	DEBUG=1
	APPBUNDLE=1

# macOS intel (SDL2, 64-bit, x86-64)
else ifeq ($(PLATFORM),osx-x86)
	LDFLAGS = -L/usr/local/lib -Lexternal/mt32emu -lSDL2_image -lSDL2_ttf -lpng -liconv -lz -lFLAC -lmpg123 -lmpeg2 -lmpeg2convert -lserialport -lportmidi -lmt32emu $(SDL_LDFLAGS) -framework IOKit -framework Foundation
	CPPFLAGS = -MD -MT $@ -MF $(@:%.o=%.d) $(SDL_CFLAGS) -I/usr/local/include -Iexternal/libguisan/include -Isrc -Isrc/osdep -Isrc/threaddep -Isrc/include -Isrc/archivers -Iexternal/floppybridge/src -Iexternal/mt32emu/src -D_FILE_OFFSET_BITS=64 $(SDL_CFLAGS)
	CXX=/usr/bin/c++
#	DEBUG=1
	APPBUNDLE=1

# Generic aarch64 target defaulting to Cortex A53 CPU (SDL2, 64-bit)
else ifeq ($(PLATFORM),a64)
	CPUFLAGS ?= -mcpu=cortex-a53
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Generic x86-64 target
else ifeq ($(PLATFORM),x86-64)

# Generic EXPERIMENTAL riscv64 target
else ifeq ($(PLATFORM),riscv64)

# RK3588 e.g. RockPi 5
else ifeq ($(PLATFORM),rk3588)
	CPUFLAGS ?= -mcpu=cortex-a76+fp
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# RK3288 e.g. Asus Tinker Board
# RK3328 e.g. PINE64 Rock64 
# RK3399 e.g. PINE64 RockPro64 
# RK3326 e.g. Odroid Go Advance - 32-bit userspace
else ifneq (,$(findstring RK,$(PLATFORM)))
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1

	ifneq (,$(findstring RK33,$(PLATFORM)))
	  CPUFLAGS = -mfloat-abi=hard -mfpu=neon-fp-armv8
	  ifneq (,$(findstring RK3399,$(PLATFORM)))
		CPUFLAGS += -mcpu=cortex-a72
	  else ifneq (,$(findstring RK3328,$(PLATFORM)))
		CPUFLAGS += -mcpu=cortex-a53
	  else ifneq (,$(findstring RK3326,$(PLATFORM)))
		CPUFLAGS += -mcpu=cortex-a35
	  endif
	else ifneq (,$(findstring RK3288,$(PLATFORM)))
	  CPUFLAGS = -mcpu=cortex-a17 -mfloat-abi=hard -mfpu=neon-vfpv4
	endif

# sun8i Allwinner H2+ / H3 like Orange PI, Nano PI, Banana PI, Tritium, AlphaCore2, MPCORE-HUB
else ifeq ($(PLATFORM),sun8i)
	CPUFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1
	ifdef DEBUG
		# Otherwise we'll get compilation errors, check https://tls.mbed.org/kb/development/arm-thumb-error-r7-cannot-be-used-in-asm-here
		# quote: The assembly code in bn_mul.h is optimized for the ARM platform and uses some registers, including r7 to efficiently do an operation. GCC also uses r7 as the frame pointer under ARM Thumb assembly.
		CFLAGS += -fomit-frame-pointer
	endif

# LePotato Libre Computer
else ifeq ($(PLATFORM),lePotato)
   CPUFLAGS = -mcpu=cortex-a53 -mabi=lp64
   CPPFLAGS += $(CPPFLAGS64)
   AARCH64 = 1

# Nvidia Jetson Nano (SDL2 64-bit)
else ifeq ($(PLATFORM),jetson-nano)
	CPUFLAGS = -mcpu=cortex-a57
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# La Frite Libre Computer
else ifeq ($(PLATFORM),mali-drm-gles2-sdl2)
	CPUFLAGS = -mcpu=cortex-a53
	CPPFLAGS += $(CPPFLAGS64)
	AARCH64 = 1

# Generic Cortex-A9 32-bit
else ifeq ($(PLATFORM),s812)
	CPUFLAGS = -mcpu=cortex-a9 -mfpu=neon-vfpv3 -mfloat-abi=hard
	CPPFLAGS += $(CPPFLAGS32) $(NEON_FLAGS)
	HAVE_NEON = 1 

else
$(error Unknown platform:$(PLATFORM))
endif

RM     = rm -f
AS     ?= as
CC     ?= gcc
CXX    ?= g++
STRIP  ?= strip
PROG   = amiberry

all: $(PROG)

export CFLAGS := $(CPUFLAGS) $(CFLAGS) $(EXTRA_CFLAGS)
export CXXFLAGS = $(CFLAGS) -std=gnu++17
export CPPFLAGS

ifdef GCC_PROFILE
	CFLAGS += -pg
	LDFLAGS += -pg
endif

ifdef GEN_PROFILE
	CFLAGS += -fprofile-generate -fprofile-arcs -fvpt
	LDFLAGS += -lgcov
endif

ifdef USE_PROFILE
	CFLAGS += -fprofile-use -fprofile-correction -fbranch-probabilities -fvpt
	LDFLAGS += -lgcov
endif

ifdef SANITIZE
	export LDFLAGS := -lasan $(LDFLAGS)
	CFLAGS += -fsanitize=leak -fsanitize-recover=address
endif

C_OBJS= \
	src/archivers/7z/7zAlloc.o \
	src/archivers/7z/7zArcIn.o \
	src/archivers/7z/7zBuf.o \
	src/archivers/7z/7zBuf2.o \
	src/archivers/7z/7zCrc.o \
	src/archivers/7z/7zCrcOpt.o \
	src/archivers/7z/7zDec.o \
	src/archivers/7z/7zFile.o \
	src/archivers/7z/7zStream.o \
	src/archivers/7z/Aes.o \
	src/archivers/7z/AesOpt.o \
	src/archivers/7z/Alloc.o \
	src/archivers/7z/Bcj2.o \
	src/archivers/7z/Bra.o \
	src/archivers/7z/Bra86.o \
	src/archivers/7z/BraIA64.o \
	src/archivers/7z/CpuArch.o \
	src/archivers/7z/Delta.o \
	src/archivers/7z/LzFind.o \
	src/archivers/7z/Lzma2Dec.o \
	src/archivers/7z/Lzma2Enc.o \
	src/archivers/7z/Lzma86Dec.o \
	src/archivers/7z/Lzma86Enc.o \
	src/archivers/7z/LzmaDec.o \
	src/archivers/7z/LzmaEnc.o \
	src/archivers/7z/LzmaLib.o \
	src/archivers/7z/Ppmd7.o \
	src/archivers/7z/Ppmd7Dec.o \
	src/archivers/7z/Ppmd7Enc.o \
	src/archivers/7z/Sha256.o \
	src/archivers/7z/Sort.o \
	src/archivers/7z/Xz.o \
	src/archivers/7z/XzCrc64.o \
	src/archivers/7z/XzCrc64Opt.o \
	src/archivers/7z/XzDec.o \
	src/archivers/7z/XzEnc.o \
	src/archivers/7z/XzIn.o \
	src/archivers/chd/utf8proc.o

OBJS = \
	src/a2065.o \
	src/a2091.o \
	src/akiko.o \
	src/amax.o \
	src/ar.o \
	src/arcadia.o \
	src/audio.o \
	src/autoconf.o \
	src/blitfunc.o \
	src/blittable.o \
	src/blitter.o \
	src/blkdev.o \
	src/blkdev_cdimage.o \
	src/bsdsocket.o \
	src/calc.o \
	src/catweasel.o \
	src/cd32_fmv.o \
	src/cd32_fmv_genlock.o \
	src/cdrom.o \
	src/cdtv.o \
	src/cdtvcr.o \
	src/cfgfile.o \
	src/cia.o \
	src/consolehook.o \
	src/cpuboard.o \
	src/crc32.o \
	src/custom.o \
	src/debug.o \
	src/debugmem.o \
	src/def_icons.o \
	src/devices.o \
	src/disasm.o \
	src/disk.o \
	src/diskutil.o \
	src/dlopen.o \
	src/dongle.o \
	src/draco.o \
	src/drawing.o \
	src/driveclick.o \
	src/enforcer.o \
	src/ethernet.o \
	src/events.o \
	src/expansion.o \
	src/fdi2raw.o \
	src/filesys.o \
	src/flashrom.o \
	src/fpp.o \
	src/fpp_native.o \
	src/framebufferboards.o \
	src/fsdb.o \
	src/fsusage.o \
	src/gayle.o \
	src/gfxboard.o \
	src/gfxlib.o \
	src/gfxutil.o \
	src/hardfile.o \
	src/hrtmon.rom.o \
	src/ide.o \
	src/idecontrollers.o \
	src/identify.o \
	src/ini.o \
	src/inputdevice.o \
	src/inputrecord.o \
	src/isofs.o \
	src/keybuf.o \
	src/luascript.o \
	src/main.o \
	src/memory.o \
	src/midiemu.o \
	src/native2amiga.o \
	src/ncr9x_scsi.o \
	src/ncr_scsi.o \
	src/parser.o \
	src/pci.o \
	src/rommgr.o \
	src/rtc.o \
	src/sampler.o \
	src/sana2.o \
	src/savestate.o \
	src/scp.o \
	src/scsi.o \
	src/scsiemul.o \
	src/scsitape.o \
	src/slirp_uae.o \
	src/sndboard.o \
	src/specialmonitors.o \
	src/statusline.o \
	src/tabletlibrary.o \
	src/test_card.o \
	src/tinyxml2.o \
	src/traps.o \
	src/uaeexe.o \
	src/uaelib.o \
	src/uaenative.o \
	src/uaeresource.o \
	src/uaeserial.o \
	src/vm.o \
	src/x86.o \
	src/zfile.o \
	src/zfile_archive.o \
	src/archivers/chd/avhuff.o \
	src/archivers/chd/bitmap.o \
	src/archivers/chd/cdrom.o \
	src/archivers/chd/chd.o \
	src/archivers/chd/chdcd.o \
	src/archivers/chd/chdcodec.o \
	src/archivers/chd/corealloc.o \
	src/archivers/chd/corefile.o \
	src/archivers/chd/corestr.o \
	src/archivers/chd/flac.o \
	src/archivers/chd/harddisk.o \
	src/archivers/chd/hashing.o \
	src/archivers/chd/huffman.o \
	src/archivers/chd/md5.o \
	src/archivers/chd/osdcore.o \
	src/archivers/chd/osdlib_unix.o \
	src/archivers/chd/osdsync.o \
	src/archivers/chd/palette.o \
	src/archivers/chd/posixdir.o \
	src/archivers/chd/posixfile.o \
	src/archivers/chd/posixptty.o \
	src/archivers/chd/posixsocket.o \
	src/archivers/chd/strconv.o \
	src/archivers/chd/strformat.o \
	src/archivers/chd/unicode.o \
	src/archivers/chd/vecstream.o \
	src/archivers/dms/crc_csum.o \
	src/archivers/dms/getbits.o \
	src/archivers/dms/maketbl.o \
	src/archivers/dms/pfile.o \
	src/archivers/dms/tables.o \
	src/archivers/dms/u_deep.o \
	src/archivers/dms/u_heavy.o \
	src/archivers/dms/u_init.o \
	src/archivers/dms/u_medium.o \
	src/archivers/dms/u_quick.o \
	src/archivers/dms/u_rle.o \
	src/archivers/lha/crcio.o \
	src/archivers/lha/dhuf.o \
	src/archivers/lha/header.o \
	src/archivers/lha/huf.o \
	src/archivers/lha/larc.o \
	src/archivers/lha/lhamaketbl.o \
	src/archivers/lha/lharc.o \
	src/archivers/lha/shuf.o \
	src/archivers/lha/slide.o \
	src/archivers/lha/uae_lha.o \
	src/archivers/lha/util.o \
	src/archivers/lzx/unlzx.o \
	src/archivers/mp2/kjmp2.o \
	src/archivers/wrp/warp.o \
	src/archivers/zip/unzip.o \
	src/caps/caps_amiberry.o \
	src/dsp3210/dsp_glue.o \
    src/dsp3210/DSP3210_emulation.o \
	src/machdep/support.o \
	src/mame/a2410.o \
	src/mame/tm34010/tms34010.o \
	external/floppybridge/src/floppybridge_lib.o \
	src/osdep/ahi_v1.o \
	src/osdep/bsdsocket_host.o \
	src/osdep/cda_play.o \
	src/osdep/charset.o \
	src/osdep/fsdb_host.o \
	src/osdep/clipboard.o \
	src/osdep/amiberry_hardfile.o \
	src/osdep/keyboard.o \
	src/osdep/midi.o \
	src/osdep/mp3decoder.o \
	src/osdep/picasso96.o \
	src/osdep/writelog.o \
	src/osdep/amiberry.o \
	src/osdep/ahi_v2.o \
	src/osdep/amiberry_dbus.o \
	src/osdep/amiberry_filesys.o \
	src/osdep/amiberry_input.o \
	src/osdep/amiberry_gfx.o \
	src/osdep/amiberry_gui.o \
	src/osdep/amiberry_mem.o \
	src/osdep/amiberry_serial.o \
	src/osdep/amiberry_uaenet.o \
	src/osdep/amiberry_whdbooter.o \
	src/osdep/ioport.o \
	src/osdep/sigsegv_handler.o \
	src/osdep/socket.o \
	src/osdep/retroarch.o \
	src/osdep/vpar.o \
	src/pcem/386.o \
    src/pcem/386_common.o \
    src/pcem/386_dynarec.o \
    src/pcem/808x.o \
    src/pcem/cpu.o \
    src/pcem/dosbox/dbopl.o \
    src/pcem/dma.o \
    src/pcem/keyboard.o \
    src/pcem/keyboard_at.o \
    src/pcem/keyboard_at_draco.o \
    src/pcem/mem.o \
    src/pcem/mouse_ps2.o \
    src/pcem/mouse_serial.o \
    src/pcem/dosbox/nukedopl.o \
    src/pcem/nvr.o \
    src/pcem/pcemglue.o \
    src/pcem/pcemrtc.o \
    src/pcem/pic.o \
    src/pcem/pit.o \
    src/pcem/serial.o \
    src/pcem/sound_cms.o \
    src/pcem/sound_dbopl.o \
    src/pcem/sound_mpu401_uart.o \
    src/pcem/sound_opl.o \
    src/pcem/sound_sb.o \
    src/pcem/sound_sb_dsp.o \
    src/pcem/sound_speaker.o \
    src/pcem/timer.o \
    src/pcem/vid_bt482_ramdac.o \
    src/pcem/vid_cl5429.o \
    src/pcem/vid_et4000.o \
    src/pcem/vid_et4000w32.o \
    src/pcem/vid_inmos.o \
    src/pcem/vid_ncr.o \
    src/pcem/vid_permedia2.o \
    src/pcem/vid_s3.o \
    src/pcem/vid_s3_virge.o \
    src/pcem/vid_sc1502x_ramdac.o \
    src/pcem/vid_sdac_ramdac.o \
    src/pcem/vid_svga.o \
    src/pcem/vid_svga_render.o \
    src/pcem/vid_voodoo.o \
    src/pcem/vid_voodoo_banshee.o \
    src/pcem/vid_voodoo_banshee_blitter.o \
    src/pcem/vid_voodoo_blitter.o \
    src/pcem/vid_voodoo_display.o \
    src/pcem/vid_voodoo_fb.o \
    src/pcem/vid_voodoo_fifo.o \
    src/pcem/vid_voodoo_reg.o \
    src/pcem/vid_voodoo_render.o \
    src/pcem/vid_voodoo_setup.o \
    src/pcem/vid_voodoo_texture.o \
    src/pcem/x86seg.o \
    src/pcem/x87.o \
    src/pcem/x87_timings.o \
    src/ppc/ppc.o \
    src/ppc/ppcd.o \
    src/qemuvga/cirrus_vga.o \
    src/qemuvga/es1370.o \
    src/qemuvga/esp.o \
    src/qemuvga/lsi53c710.o \
    src/qemuvga/lsi53c895a.o \
    src/qemuvga/ne2000.o \
    src/qemuvga/qemu.o \
    src/qemuvga/qemuuaeglue.o \
    src/qemuvga/vga.o \
	src/sounddep/sound.o \
	src/threaddep/threading.o \
	src/osdep/gui/ControllerMap.o \
	src/osdep/gui/CreateFolder.o \
	src/osdep/gui/SelectorEntry.o \
	src/osdep/gui/ShowCustomFields.o \
	src/osdep/gui/ShowHelp.o \
	src/osdep/gui/ShowMessage.o \
	src/osdep/gui/ShowDiskInfo.o \
	src/osdep/gui/SelectFolder.o \
	src/osdep/gui/SelectFile.o \
	src/osdep/gui/CreateFilesysHardfile.o \
	src/osdep/gui/EditFilesysVirtual.o \
	src/osdep/gui/EditFilesysHardfile.o \
	src/osdep/gui/EditFilesysHardDrive.o \
	src/osdep/gui/EditTapeDrive.o \
	src/osdep/gui/PanelAbout.o \
	src/osdep/gui/PanelPaths.o \
	src/osdep/gui/PanelQuickstart.o \
	src/osdep/gui/PanelConfig.o \
	src/osdep/gui/PanelCPU.o \
	src/osdep/gui/PanelChipset.o \
	src/osdep/gui/PanelCustom.o \
	src/osdep/gui/PanelROM.o \
	src/osdep/gui/PanelRAM.o \
	src/osdep/gui/PanelFloppy.o \
	src/osdep/gui/PanelExpansions.o \
	src/osdep/gui/PanelHD.o \
	src/osdep/gui/PanelRTG.o \
	src/osdep/gui/PanelHWInfo.o \
	src/osdep/gui/PanelInput.o \
	src/osdep/gui/PanelIOPorts.o \
	src/osdep/gui/PanelDisplay.o \
	src/osdep/gui/PanelSound.o \
	src/osdep/gui/PanelDiskSwapper.o \
	src/osdep/gui/PanelMisc.o \
	src/osdep/gui/PanelPrio.o \
	src/osdep/gui/PanelSavestate.o \
	src/osdep/gui/PanelVirtualKeyboard.o \
	src/osdep/gui/PanelWHDLoad.o \
	src/osdep/gui/main_window.o \
	src/osdep/gui/Navigation.o \
	src/osdep/vkbd/vkbd.o \
	src/newcpu.o \
	src/newcpu_common.o \
	src/readcpu.o \
	src/cpudefs.o \
	src/cpustbl.o \
	src/cpummu.o \
	src/cpummu30.o \
	src/cpuemu_0.o \
	src/cpuemu_11.o \
	src/cpuemu_13.o \
	src/cpuemu_20.o \
	src/cpuemu_21.o \
	src/cpuemu_22.o \
	src/cpuemu_23.o \
	src/cpuemu_24.o \
	src/cpuemu_31.o \
	src/cpuemu_32.o \
	src/cpuemu_33.o \
	src/cpuemu_34.o \
	src/cpuemu_35.o \
	src/cpuemu_40.o \
	src/cpuemu_50.o \
	src/jit/compemu.o \
	src/jit/compstbl.o \
	src/jit/compemu_support.o \
	src/jit/compemu_fpp.o

DEPS = $(OBJS:%.o=%.d) $(C_OBJS:%.o=%.d)

$(PROG): $(OBJS) $(C_OBJS) guisan mt32emu floppybridge capsimg
	$(CXX) -o $(PROG) $(OBJS) $(C_OBJS) $(LDFLAGS)
ifndef DEBUG
# want to keep a copy of the binary before stripping? Then enable the below line
#	cp $(PROG) $(PROG)-debug
	$(STRIP) $(PROG)
endif
ifdef	APPBUNDLE
	sh make-bundle.sh
endif

gencpu:
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) -o gencpu src/cpudefs.cpp src/gencpu.cpp src/readcpu.cpp src/osdep/charset.cpp

gencomp:
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) -o gencomp src/jit/gencomp.cpp src/cpudefs.cpp src/readcpu.cpp src/osdep/charset.cpp

gencomp_arm:
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) -o gencomp_arm src/jit/gencomp_arm.c src/cpudefs.cpp src/readcpu.cpp src/osdep/charset.cpp

clean:
	$(RM) $(PROG) $(PROG)-debug $(C_OBJS) $(OBJS) $(ASMS) $(DEPS)
	$(MAKE) -C external/libguisan clean && $(RM) external/libguisan/libguisan.a
	$(RM) -r external/mt32emu/build
	$(RM) external/mt32emu/libmt32emu.a
	$(RM) -r external/floppybridge/build
	$(RM) external/floppybridge/libfloppybridge.so
	$(RM) -r external/capsimage/build
	$(RM) external/capsimage/libcapsimage.so

cleanprofile:
	$(RM) $(OBJS:%.o=%.gcda)
	$(MAKE) -C external/libguisan cleanprofile

# The GUI library that Amiberry uses
guisan:
	$(MAKE) -C external/libguisan

# The MT32 emulator library that Amiberry uses, for internal MIDI emulation
mt32emu:
	cmake -DCMAKE_BUILD_TYPE=Release -Dlibmt32emu_SHARED=FALSE -S external/mt32emu -B external/mt32emu/build
	cmake --build external/mt32emu/build --target all --parallel
	cp external/mt32emu/build/libmt32emu.a external/mt32emu/

# Optional external libraries (plugins)

# The floppy bridge library that Amiberry uses, for accessing floppy drives
floppybridge:
	cmake -DCMAKE_BUILD_TYPE=Release -S external/floppybridge -B external/floppybridge/build
	cmake --build external/floppybridge/build --target all --parallel
	cp external/floppybridge/build/libfloppybridge.so ./plugins

# The CAPSImg library that Amiberry uses, for accessing IPF disk images
capsimg:
	cmake -DCMAKE_BUILD_TYPE=Release -S external/capsimage -B external/capsimage/build
	cmake --build external/capsimage/build --target all --parallel
	cp external/capsimage/build/libcapsimage.so ./plugins

-include $(DEPS)
