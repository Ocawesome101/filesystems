# CFS

The Cynosure File System

This filesystem is built for small (<1GB) hard disks.  As such, it does not have support for more than 65,535 files.  It is also built for relative simplicity while still having access to a full POSIX-like suite of features (permissions, ownership, access times, etc).  A great deal of inspiration is taken from the Second Extended File System.

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
  char[64] last_mount_path;
  // reserved for future use
  char[376] padding;
}
```
After the superblock come the inode and block bitmaps.  The inode bitmap contains `Superblock.inodes` bits (rounded up to the nearest byte), each of which specifies one inode's being used or unused.  Immediately following this (starting in the next sector!) is the block bitmap, which contains `Superblock.blocks` bits and indicates whether a block has been used or not.

After this comes the inode table, a preallocated space containing data for all inodes.  The first inode is always set as the root directory.

There are exactly two inodes per sector in the inode table.  Each inode is exactly 256 bytes.
```c
struct Inode {
  // File type and permissions - see below
  uint16 mode;
  // UID that owns the file
  uint16 uid;
  // GID that owns the file
  uint16 gid;
  // last access time
  uint64 access;
  // creation time
  uint64 create;
  // last modification time
  uint64 modify;
  // file size
  uint32 size;
  // number of times this inode is referenced
  uint16 references;
  // pointer to the first data block (holds pointers to the real data blocks)
  uint32 datablock;
  // file name - not null-terminated but trailing zeroes should be stripped
  // may under no circumstances contain a slash (/)
  char[64] filename;
  // extended inode data
  char[152] extended_data;
}
```

If the inode is a regular file, its `datablock` contains 32 pointers to data blocks.  If an inode is a directory, its `datablock` contains 16-bit references to other inodes.  If an inode is a symbolic link *and* the path it references is longer than 152 bytes, its datablock contains the path which the link references.  Otherwise, it is stored in the inode's `extended_data`.  If the inode is a character device, block device, or FIFO, the `extended_data` section contains information about its parameters and the `datablock` pointer will be `0`.

#### File Modes
These are effectively EXT2's file modes shuffled around a bit.
| Value  | Description      |
| ------ | ---------------- |
| 0x0001 | owner read       |
| 0x0002 | owner write      |
| 0x0004 | owner execute    |
| 0x0008 | group read       |
| 0x0010 | group write      |
| 0x0020 | group execute    |
| 0x0040 | others read      |
| 0x0080 | others write     |
| 0x0100 | others execute   |
| 0x0200 | setuid bit       |
| 0x0400 | setgid bit       |
| 0x0800 | sticky bit       |
| | Final 4 bits denote type |
| 0x1000 | regular file     |
| 0x2000 | directory        |
| 0x4000 | character device |
| 0x6000 | block device     |
| 0x8000 | symbolic link    |
| 0xA000 | socket           |
| 0xC000 | FIFO             |

## Recommended Filesystem Counts
These counts are not fixed, and may be modified to change the balance of file count to file size.  However, those listed here should be sufficient for most uses.  These should be the defaults for a `mkfs.cfs` utility.

Note that these *may not* be changed after filesystem creation without the use of special tools.

On a 4MB filesystem, the recommended counts for these (and the space they will consume) are:
  - Inodes: 1536, inode bitmap 192 bytes, inode table 384KB (768 sectors)
  - Blocks: 3710, block bitmap 464 bytes

This limits the total filesystem size to about 3.6MB.

On a 2MB filesystem, the recommended counts are:
  - Inodes: 768, inode bitmap 96 bytes, inode table 192KB (384 sectors)
  - Blocks: 1854, block bitmap 232 bytes

This limits the total size of the filesystem to about 1.8MB.

On a 1MB filesystem, the recommended counts are:
  - Inodes: 640, inode bitmap 80 bytes, inode table 160KB (320 sectors)
  - Blocks: 862, block bitmap 108 bytes

This limits the total filesystem size to 862KB.

On a 512KB filesystem, the recommended counts are:
  - Inodes: 256, inode bitmap 32 bytes, inode table 64KB (128 sectors)
  - Blocks: 446, block bitmap 56 bytes

This limits the total filesystem size to 446KB.


