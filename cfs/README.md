# CFS

The Cynosure File System

This filesystem is built for small (<1GB) hard disks.  As such, it does not have support for more than 65,535 files.  It is also built for relative simplicity while still having access to a full POSIX-like suite of features (permissions, ownership, access times, etc).

Sectors are assumed to be 512 bytes.  All numbers are stored in little-endian format.  All sector indices are 1-based, in keeping with Lua convention.

The first sector of the disk will always contain code to load the boot loader from a fixed offset.  Whether the BIOS uses this is optional.

The Filesystem Information Section (hereafter "FIS") resides immediately after this, at sector 2.

```c
struct Superblock {
  // The filesystem signature "\x1bCFS"
  char[4] signature;
  // Filesystem major revision
  uint32 rev_major;
  // Filesystem minor revision
  uint32 rev_minor;
  // OS that created the filesystem
  uint32 osid;
  // Filesystem UUID
  char[16] uuid;
  // Inode count
  uint16 inodes;
  // Block count (1 block = 2 sectors)
  uint16 blocks;
  // Total used blocks
  uint32 used;
  // Volume name
  char[32] volume_name;
  // Last mount path
  char[255] last_mount_path;
}
```

```c
struct Inode {

}
```
