--[[
    Reference implementation of the Cynosure File
    System.

    Copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--

local _ = require("struct")
local struct = _.struct

local superblock = struct {
  _.char[4] "signature",
  _.uint32 "rev_major",
  _.uint32 "rev_minor",
  _.uint32 "osid",
  _.char[14] "uuid",
  _.uint16 "inodes",
  _.uint16 "blocks",
  _.uint16 "used_inodes",
  _.uint16 "used_blocks",
}

local function new(drive)
  if checkArg then checkArg(1, drive, "table") end
end
