# CFS

The Cynosure File System

Sectors are assumed to be 512 bytes.  All numbers are stored in little-endian format.  All sector indices are 1-based, in keeping with Lua convention.

The first sector of the disk will always contain code to load the boot loader from a fixed offset.  Whether the BIOS uses this is optional.

The Filesystem Information Section (hereafter "FIS") resides immediately after this, at sector 2.

```c
struct Superblock {
  char[4] signature;
  char[16] volname;
}
```
