#!/bin/sh
BASE_DIR=`pwd`
LIBEVENT_PATH="$BASE_DIR/deps/libevent2"
TCMALLOC_PATH="$BASE_DIR/deps/gperftools2"

if test -z "$TARGET_OS"; then
    TARGET_OS=`uname -s`
fi
if test -z "$MAKE"; then
    MAKE=make
fi
if test -z "$CC"; then
    CC=gcc
fi
if test -z "$CXX"; then
    CXX=g++
fi

case "$TARGET_OS" in
    Darwin)
        PLATFORM_CLIBS="-ldl -pthread -std=c++0x"
        ;;
    Linux)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    OS_ANDROID_CROSSCOMPILE)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    CYGWIN_*)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    SunOS)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    FreeBSD)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        MAKE=gmake
        ;;
    NetBSD)
        PLATFORM_CLIBS="-ldl -pthread -lgcc_s -lrt -std=c++0x"
        ;;
    OpenBSD)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    DragonFly)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    HP-UX)
        PLATFORM_CLIBS="-ldl -pthread -lrt -std=c++0x"
        ;;
    *)
        echo "Unknown platform!" >&2
        exit 1
esac

DIR=`pwd`
cd $LIBEVENT_PATH
if [ ! -f "$LIBEVENT_PATH/.libs/libevent.a" ]; then
    echo ""
    echo "##### building libevent... #####"
    ./configure
    make
    cp "$LIBEVENT_PATH/event.h" "$LIBEVENT_PATH/include/event.h"
    cp "$LIBEVENT_PATH/evutil.h" "$LIBEVENT_PATH/include/evutil.h"
    echo "##### building libevent finished #####"
    echo ""
fi
cd "$DIR"

DIR=`pwd`
cd $TCMALLOC_PATH
if [ ! -f "$TCMALLOC_PATH/.libs/libtcmalloc_minimal.a" ]; then
    echo ""
    echo "##### building tcmalloc... #####"
    ./configure --disable-cpu-profiler --disable-heap-profiler --disable-heap-checker --disable-debugalloc --enable-minimal
    make
    echo "##### building tcmalloc finished #####"
    echo ""
fi
cd "$DIR"

rm -f build_config.mk
echo CC=$CC >> build_config.mk
echo CXX=$CXX >> build_config.mk
echo "MAKE=$MAKE" >> build_config.mk
echo "LIBEVENT_PATH=$LIBEVENT_PATH" >> build_config.mk

echo "CFLAGS=" >> build_config.mk
echo "CFLAGS = -DNDEBUG -D__STDC_FORMAT_MACROS -g -O2 -Wno-sign-compare" >> build_config.mk
echo "CFLAGS += ${PLATFORM_CFLAGS}" >> build_config.mk
echo "CFLAGS += -I \"$LIBEVENT_PATH/include\"" >> build_config.mk
echo "CFLAGS += -I \"../../cpp/include\"" >> build_config.mk
echo "CFLAGS += -I \"../../cpp/\"" >> build_config.mk
echo "CFLAGS += -I \"../../cpp/RedisSentinel\"" >> build_config.mk
echo "CFLAGS += -I \"/usr/local/bfd/include/\"" >> build_config.mk
echo "CFLAGS += -I \"/usr/local/include/zookeeper\"" >> build_config.mk

echo "CLIBS=" >> build_config.mk
echo "CLIBS += ${PLATFORM_CLIBS}" >> build_config.mk
echo "CLIBS += \"$LIBEVENT_PATH/.libs/libevent.a\"" >> build_config.mk
echo "CLIBS += -L \"/home/meng.wei/redis-sentinel-client/release\" -lkvdb" >> build_config.mk
echo "CLIBS += -L \"/usr/local/bfd/lib64\"" -lboost_thread >> build_config.mk

if [ -f "$TCMALLOC_PATH/.libs/libtcmalloc_minimal.a" ]; then
    echo "CLIBS += \"$TCMALLOC_PATH/.libs/libtcmalloc_minimal.a\"" >> build_config.mk
fi
echo "##tips: if stoped, please run command [make] again ##"
