--[[
    Reference implementation of the Cynosure File
    System.

    Copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--


local INODEBMP = 3
local BLOCKBMP = 4

local _ = require("struct")
local struct = _.struct

local cfs = {}

cfs.superblock = struct {
  _.char[4] "signature",
  _.uint32 "rev_major",
  _.uint32 "rev_minor",
  _.uint32 "osid",
  _.char[16] "uuid",
  _.uint16 "inodes",
  _.uint16 "blocks",
  _.uint16 "used_inodes",
  _.uint16 "used_blocks",
  _.char[32] "volume_name",
  _.char[64] "last_mount_path",
  _.char[376] "padding"
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

cfs.modes = {
  ownerr = 0x1,
  ownerw = 0x2,
  ownerx = 0x4,
  groupr = 0x8,
  groupw = 0x10,
  groupx = 0x20,
  otherr = 0x40,
  otherw = 0x80,
  otherx = 0x100,
  setuid = 0x200,
  setgid = 0x400,
  sticky = 0x800,
  f_regular   = 0x1000,
  f_directory = 0x2000,
  f_chardev   = 0x6000,
  f_blkdev    = 0x8000,
  f_symlink   = 0xA000,
  f_fifo      = 0xC000
}

local _fsobj = {}

function _fsobj:_getBitmapByte(sector, n)
  local bit = 2^((n%8)-1)
  local byte = ((sector - 1) * 512) + math.ceil((n-1) / 8)
  return bit, byte
end

function _fsobj:_readFromBitmap(sector, n)
  local bmask, byte = self:_getBitmapByte(sector, n)
  return self.drive.readByte(byte) & bmask
end

function _fsobj:_writeToBitmap(sector, n, on)
  local bmask, byte = self._getBitmapByte(sector, n)
  local bdat = self.drive.readByte(byte)
  if on then
    bdat = bdat | bmask
  else
    if bdat & bmask ~= 0 then
      bdat = bdat ~ bmask
    end
  end
  self.drive.writeByte(byte, bdat)
end

-- inodes are 1-indexed
function _fsobj:_readInode(n)
  local offset = 4
  if self:_readFromBitmap(INODEBMP, n) == 0 then
    return nil
  end
  
  local _data = self.drive.readSector(offset + n)
  if n % 2 == 1 then -- first inode in the sector
    _data = _data:sub(1, 256)
  else -- second inode in the sector
    _data = _data:sub(257)
  end

  local data = cfs.inode(_data)
  data.filename = data.filename:gsub("\0", "")
  return data
end

-- blocks are 0-indexed
function _fsobj:_readBlock(n)
  -- compute sector offset
  local offset = 4 + math.ceil(self.fis.inodes / 2)
  -- 1 block = 2 sectors
  n = n * 2
  local data = self.drive.readSector(n) .. self.drive.readSector(n + 1)
  return data
end

function _fsobj:_readDataBlock(dblock, ptrlist)
  local ptrs = ptrlist or {}
  for ptr in dblock:gmatch("..") do
    local _ptr = string.unpack("<I2", ptr)
    if _ptr == 0 then break end
    if #ptrs == 510 then -- 32-bit pointer
      _ptr = string.unpack("<I4", dblock:sub(-4))
      if _ptr > 0 then
        self:_readDataBlock(self:_readBlock(_ptr), ptrs)
      end
    else
      ptrs[#ptrs+1] = _ptr
    end
  end
  return ptrs
end

function _fsobj:_listDirInode(indat)
  local dblock = self:_readBlock(indat.datablock)
  local inodes = self:_readDataBlock(dblock)
  return inodes
end

local function clean(path)
  local segs = {}
  for seg in path:gmatch("[^/]+") do
    if seg == ".." then
      segs[#segs] = nil
    elseif seg ~= "." then
      segs[#segs+1] = seg
    end
  end
  return segs
end

function _fsobj:_resolve(path)
  path = clean(path)
  local root = self:_readInode(1)
  local inodes = self:_listDirInode(root)
end

-- -------------------------------------- --
-- actual user-level functions begin here --
-- -------------------------------------- --

function _fsobj:stat(file)
end

function cfs.new(drive)
  if checkArg then checkArg(1, drive, "table") end

  local new = setmetatable({drive = drive, cache = {}}, {__index = _fsobj})

  local superblock = cfs.superblock(drive.readSector(2))
  if superblock.signature ~= "\x1bCFS" then
    error "FIS contains bad filesystem signature"
  end

  superblock.uuid = superblock.uuid
    :gsub(".", function(a) return ("%02x"):format(a:byte()) end)
    :gsub("(........)(....)(....)(....)(............)", "%1-%2-%3-%4-%5")
  --for k, v in pairs(superblock) do if k ~= "padding" then print(k, v) end end

  new.fis = superblock

  local rootdir = new:_readInode(1)
  for k,v in pairs(rootdir) do print(k,v) end

  return new
end

return cfs
