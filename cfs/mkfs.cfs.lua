-- mkfs.cfs --
-- format a drive as CFS

print("mkfs.cfs (c) 2021 Ocawesome101")

local cfs = require("cfs")
local drive = require("component").drive

local uuid = require("uuid").next()
print("UUID: " .. uuid)
uuid = string.pack("<c16", (uuid:gsub("%-", ""):gsub("%x%x",function(c)
  return string.char(tonumber(c,16))end)))

local capacity = drive.getCapacity() / 512
local fis = cfs.superblock {
  signature = "\x1bCFS",
  rev_major = 0,
  rev_minor = 0,
  osid = 0,
  uuid = uuid,
  inodes = (capacity == 8192) and 1536 or 0,
  blocks = (capacity == 8192) and 3710 or 0,
  used_inodes = 1,
  used_blocks = 0,
  volume_name = "made with mkfs.cfs",
  last_mount_path = "",
  padding = ""
}

print("writing FIS")
drive.writeSector(2, fis)

print("writing inode + block bitmaps")
drive.writeSector(3, "\1"..string.rep("\0", 511))
drive.writeSector(4, "\1"..string.rep("\0", 511))

print("zeroing inode sectors")
for i=1, 768, 1 do
  drive.writeSector(i+4, string.rep("\0", 512))
end

print("writing rootfs inode")
drive.writeSector(5, cfs.inode {
  mode = cfs.modes.ownerr | cfs.modes.ownerw | cfs.modes.ownerx
       | cfs.modes.f_directory,
  uid = 0,
  gid = 0,
  access = os.time(),
  create = os.time(),
  modify = os.time(),
  size = 1024,
  references = 1,
  datablock = 0,
  filename = "/",
  extended_data = ""
})

print("done")
