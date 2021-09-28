--[[
    Reference implementation of the Cynosure File
    System.

    Copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--

local _ = require("struct")
local struct = _.struct

local superblock = struct {
  _.char[4] "signature";
}

local function new(drive)
  if checkArg then checkArg(1, drive, "table") end
end
