---
title: Untitled 7
tags: []
draft: true
date: 2026-06-09
---
# Reverse engineering Asus RT-AC1900 firmware


after the extraction, we have 2 files
![[Pasted image 20260609013123.png]]

i am particularly interested with partition_1.bin since it contains the squashfs file system. 

extract the squashFS 

```
sudo unsquashfs -d router_fs partition_1.bin 
```
![[Pasted image 20260609020615.png]]

Now, we have the file system
![[Pasted image 20260609020630.png]]

next step is identifying the architecture. QEMU uses different binaries for each arch 
`file router_fs/bin/busybox`
![[Pasted image 20260609020806.png]]

we also need to identify the architecture variant as buildroot requires it later on. 
`readelf -A router_fs/bin/busybox` (`readelf` is a commnad that displays information about executable and ELF files)
![[Pasted image 20260609021328.png]]
=> so the architecture is ARMv7-A. 
From looking up the model from the main website, we know that the router uses a Broadcom BCM4709A SoC whose CPU is an ARM Cortex-A9 dual-core. 

![[Pasted image 20260609024224.png]]

In the Toolchain options, leave everything as default except for the C library. We must match it as uClibc-ng, not glibc as default. 

![[Pasted image 20260609024354.png]]

in the System configuration option change the Root filesystem overlay directories to the path to the router_fs directory that was extracted from the .trx image file 
![[Pasted image 20260609024730.png]]

the firmware is based on a 4.1.x kernel so we should change it to the same version. 

for Kernel option, change the Kernel version to the correct version and in Kernel configuration, pick use the default architecture configuration. Then, choose the option build a Device Tree Blob. QEMU will require this later. choose the option In-tree Device Tree Source file names and type `vexpress-v2p-ca9`.

![[Pasted image 20260609030401.png]]
for Filesystem images option, choose the ext2/3/4 root filesystem option with variant ext4

![[Pasted image 20260609030047.png]]

![[Pasted image 20260609025349.png]]

the kernel version is 2.6.36.4 

we run into an issue that the compilation failed because the kernel version is too old for the gcc. 

![[Pasted image 20260609131622.png]]



```
docker run -it --rm -v $(pwd):/buildroot ubuntu:14.04 bash
```


skip building documentation 
```
make MAKEINFO=true
```


a successful build 
![[Pasted image 20260609163947.png]]

The output images are under /buildroot/output/images
![[Pasted image 20260609164009.png]]


before boot with QEMU, we need to resize the disk image to 256MB

```
sudo resize2fs rootfs.ext2 256M
```
![[Pasted image 20260609164817.png]]

```
qemu-system-arm -M vexpress-a9 -cpu cortex-a9 -m 256M -kernel zImage -dtb vexpress-v2p-ca9.dtb -drive file=rootfs.ext2,format=raw,if=sd -append "root=/dev/mmcblk0 rw console=ttyAMA0,115200" -nographic -net nic,model=lan9118 -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::2222-:22
```

in case yo u need to terminate the process, do Ctrl A and then X 

the kernel doesn't have the virtio block driver compiled in so we have to go back to the container and enable it. 
![[Pasted image 20260609165643.png]]



the router filesystem was built on speicific hardware, so to run it on a different machine, we need: 
- a kernel 
- a root FS 
we already have the root FS. 

the target architecture should be the architecture that the machine has. 
in this case, I'm going to emulate this firmware on an x86-64 machine. 


the router uClibc versiokn different than buildroot 2013 
the router binaries need the router's exact uClic libs. 


---
notes:
- /etc/hosts is generated at runtme for embeeded devices, not stored in falsh 
- for buildroot we have to create a minimal /etc/hosts 


use the package `qemu-user-static` to test teh binary directly on the host 

inside the qemu full system emulation, /bin/sh syminks to busybox but it is using buildroot's busybox not the router's 


make sure that buildroot uses the same busybox binaries as the router. 
