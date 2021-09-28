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
After the superblock come the inode and block bitmaps.

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
  uint64 size;
  // number of times this inode is referenced
  uint16 references;
  // file name - not null-terminated but trailing zeroes should be stripped
  // may under no circumstances contain a slash (/)
  char[255] filename;
}
```

<table>
  <thead>
    <th colspan="3">File Modes</th>
  </thead>
  <tbody>
    <tr>
      <th>Value</th>
      <th>Description</th>
    </tr>
    <tr>
      <tb colspan="3"> -- Permissions -- </tb>
    </tr>
    <tr>
      <tb>0x0001</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0002</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0004</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0008</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0010</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0020</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0040</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0080</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0100</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0200</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0400</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x0800</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x1000</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x2000</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x4000</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0x8000</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0xa000</tb>
      <tb></tb>
    </tr>
    <tr>
      <tb>0xc000</tb>
      <tb></tb>
    </tr>
  </tbody>
</table>
