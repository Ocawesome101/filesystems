--[[
    Reference implementation of the Cynosure File
    System.

    Copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--

local _ = require("struct")
local struct = _.struct

local cfs = {}

cfs.superblock = struct {
  _.char[4] "signature",
  _.uint32 "rev_major",
  _.uint32 "rev_minor",
  _.uint32 "osid",
  _.char[14] "uuid",
  _.uint16 "inodes",
  _.uint16 "blocks",
  _.uint16 "used_inodes",
  _.uint16 "used_blocks",
  _.char[32] "volume_name",
  _.char[64] "last_mount_path",
  -- padding
}

cfs.inode = struct {
  _.uint16 "mode",
  _.uint16 "uid",
  _.uint16 "gid",
  _.uint64 "access",
  _.uint64 "create",
  _.uint64 "modify",
  _.uint32 "size",
  _.uint16 "references",
  _.uint32 "datablock",
  _.char[64] "filename",
  _.char[64] "extended_data"
}

cfs.perms = {
  ownerr = 0x1
  ownerw = 0x2
  ownerx = 0x4
  groupr = 0x8
  groupw = 0x10
  groupx = 0x20
  otherr = 0x40
  otherw = 0x80
  otherx = 0x100
  setuid = 0x200
  setgid = 0x400
  sticky = 0x800
}

function cfs.new(drive)
  if checkArg then checkArg(1, drive, "table") end

  local superblock = cfs.superblock(drive.readSector(2))

  
end

return cfs
