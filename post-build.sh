#!/bin/sh
# assisted by claude 
# replace buildroot uClibc with router's uClibc
TARGET=$1
rm -f $TARGET/lib/libc.so.0
rm -f $TARGET/lib/ld-uClibc.so.0
rm -f $TARGET/lib/ld-uClibc-*.so
rm -f $TARGET/lib/libuClibc-*.so

cp -f /router_fs/lib/libc.so.0 $TARGET/lib/
cp -f /router_fs/lib/ld-uClibc.so.0 $TARGET/lib/
cp -f /router_fs/lib/libdl.so.0 $TARGET/lib/
cp -f /router_fs/lib/libm.so.0 $TARGET/lib/
cp -f /router_fs/lib/libpthread.so.0 $TARGET/lib/
cp -f /router_fs/lib/librt.so.0 $TARGET/lib/
cp -f /router_fs/lib/libgcc_s.so.1 $TARGET/lib/
cp -f /router_fs/bin/busybox $TARGET/lib/
