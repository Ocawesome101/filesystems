--[[
    An implementation of the Second Extended
    Filesystem for OpenComputers.  Only supports
    1KB block sizes.

    Copyright (c) 2021 Ocawesome101 under the DSLv2.
    
    ]]--

local _ = require("struct")
local struct = _.struct

local superblock = struct {
  _.uint4 "inodes_count",
  _.uint4 "blocks_count",
  _.uint4 "r_blocks_count",
  _.uint4 "free_blocks_count",
  _.uint4 "free_inodes_count",
  _.uint4 "first_data_block",
  _.uint4 "log_frag_size",
  _.uint4 "blocks_per_group",
  _.uint4 "frags_per_group",
  _.uint4 "inodes_per_group",
  _.uint4 "mtime",
  _.uint4 "wtime",
  _.uint2 "mnt_count",
  _.uint2 "max_mnt_count",
  _.uint2 "magic",
  _.uint2 "state",
  _.uint2 "errors",
  _.uint2 "minor_rev_level",
  _.uint4 "lastcheck",
  _.uint4 "checkinterval",
  _.uint4 "creator_os",
  _.uint4 "rev_level",
  _.uint2 "def_resuid",
  _.uint2 "def_resgid",
}

local block_group_descriptor = struct {
  _.uint4 "block_bitmap",
  _.uint4 "inode_bitmap",
  _.uint4 "inode_table",
  _.uint2 "free_blocks_count",
  _.uint2 "free_inodes_count",
  _.uint2 "used_dirs_count",
  _.uint2 "pad",
  _.uint12 "reserved"
}

local inode = struct {
  _.uint2 "mode",
  _.uint2 "uid",
  _.uint4 "size",
  _.uint4 "atime",
  _.uint4 "ctime",
  _.uint4 "mtime",
  _.uint4 "dtime",
  _.uint2 "gid",
  _.uint2 "links_count",
  _.uint4 "blocks",
  _.uint4 "flags",
  _.uint4 "osd1",
  _.char[15*4] "block",
  _.uint4 "generation",
  _.uint4 "file_acl",
  _.uint4 "dir_acl",
  _.uint4 "faddr",
  _.char[12] "osd2",
}

local _fsobj = {}

local function new(drive)
  if checkArg then checkArg(1, drive, "table") end
  local new = setmetatable({
    drive = drive,
  }, {__index = _fsobj})
  return new
end

return new
