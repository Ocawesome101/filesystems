--[[
    Reference implementation of the Cynosure File
    System.  This implementation currently does
    not correctly handle inode or block counts
    exceeding 4096.

    Copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--

--[[
TODO:
 [ ] Caching for:
  - [ ] Path resolutions
  - [ ] Inodes
  - [ ] Directory blocks?

--]]
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
  otherx = 0x1,
  otherw = 0x2,
  otherr = 0x4,
  groupx = 0x8,
  groupw = 0x10,
  groupr = 0x20,
  ownerx = 0x40,
  ownerw = 0x80,
  ownerr = 0x100,
  sticky = 0x200,
  setgid = 0x400,
  setuid = 0x800,
  f_fifo      = 0x1000,
  f_directory = 0x2000,
  f_blkdev    = 0x6000,
  f_regular   = 0x8000,
  f_symlink   = 0xA000,
  f_socket    = 0xC000
}

local _fsobj = {}

local function getBitmapByte(sector, n)
  local bit = 2^(n%8)
  local byte = ((sector - 1) * 512) + math.ceil((n+0.1) / 8)
  return bit, byte
end

function _fsobj:_readFromBitmap(sector, n)
  local bmask, byte = getBitmapByte(sector, n)
  return self.drive.readByte(byte) & bmask ~= 0
end

function _fsobj:_writeToBitmap(sector, n, on)
  local bmask, byte = getBitmapByte(sector, n)
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

--[[
function _fsobj:_allocateInode(mode)
  local _bitmap = self.drive.readSector(INODEBMP)
  local index = _bitmap:find("[^\255]")
  local byte = _bitmap:sub(index, index):byte()
  for i=0, 7, 1 do
    if byte & 2^i == 0 then
      local _bmsk, _byte = getBitmapByte(INODEBMP, i+1)
      self:_writeToBitmap(INODEBMP, 1, true)
      self.fis.used_inodes = self.fis.used_inodes + 1
      self.drive.writeSector(2, cfs.superblock(self.fis))
      
      return math.log(_bmsk, 2) + ((_byte - 1024) * 8)
    end
  end
  return nil, "all inodes are used"
end]]

-- TODO: need a much smarter algorithm for finding unused blocks
function _fsobj:_allocateInode()
  if self.fis.used_inodes >= self.fis.inodes then
    return nil, "no inodes left on device"
  end
  self.fis.used_inodes = self.fis.used_inodes + 1
  self:_writeToBitmap(INODEBMP, self.fis.used_inodes, true)
  self.drive.writeSector(2, cfs.superblock(self.fis))
  return self.fis.used_inodes
end

function _fsobj:_allocateBlock()
  if self.fis.used_blocks >= self.fis.blocks then
    return nil, "no blocks left on device"
  end
  self.fis.used_blocks = self.fis.used_blocks + 1
  self:_writeToBitmap(BLOCKBMP, self.fis.used_blocks, true)
  self.drive.writeSector(2, cfs.superblock(self.fis))
  return self.fis.used_blocks
end

-- inodes are 1-indexed
function _fsobj:_readInode(n)
  local offset = 4
  if self:_readFromBitmap(INODEBMP, n-1) == 0 then
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

function _fsobj:_writeInode(n, indat)
  local offset = 4
  if self:_readFromBitmap(INODEBMP, n-1) == 0 then
    return nil
  end

  local data = cfs.inode(indat)
  local _data = self.drive.readSector(offset + n)
  if n % 2 == 1 then
    data = data .. _data:sub(257)
  else
    data = _data:sub(1, 256) .. data
  end
  self.drive.writeSector(offset + n, data)
  return true
end

-- blocks are 0-indexed
function _fsobj:_readBlock(n)
  -- check if the block is allocated
  if self:_readFromBitmap(BLOCKBMP, n) == 0 then
    return nil
  end
  -- compute sector offset
  local offset = 4 + math.ceil(self.fis.inodes / 2)
  -- 1 block = 2 sectors
  n = n * 2
  local data = self.drive.readSector(offset + n)
            .. self.drive.readSector(offset + n + 1)
  return data
end

function _fsobj:_writeBlock(n, data)
  if self:_readFromBitmap(BLOCKBMP, n) == 0 then
    return nil
  end
  if #data < 1024 then
    data = data .. ("\0"):rep(1024 - #data)
  end
  local offset = 4 + math.ceil(self.fis.inodes / 2)
  n = n * 2
  local _s1, _s2 = data:sub(1, 512), data:sub(513)
  self.drive.writeSector(offset + n, _s1)
  self.drive.writeSector(offset + n + 1, _s2)
  return true
end

function _fsobj:_readDataBlock(dblock, ptrlist, blklist)
  local ptrs, blocks = ptrlist or {}, blklist or {}
  for ptr in dblock:gmatch("..") do
    local _ptr = string.unpack("<I2", ptr)
    if _ptr == 0 then break end
    if #ptrs == 510 then -- 32-bit pointer
      _ptr = string.unpack("<I4", dblock:sub(-4))
      if _ptr > 0 then
        blocks[#blocks+1] = _ptr
        self:_readDataBlock(self:_readBlock(_ptr), ptrs, blocks)
      end
      break
    else
      ptrs[#ptrs+1] = _ptr
    end
  end
  return ptrs, blocks
end

-- get all children of a directory inode
function _fsobj:_listDirInode(indat)
  local dblock = self:_readBlock(indat.datablock)
  local inodes, blocks = self:_readDataBlock(dblock)
  table.insert(blocks, 1, indat.datablock)
  return inodes, blocks
end

function _fsobj:_saveDirInode(indat, ptrs, blocks)
  local saved = 0
  local blkidx = 0
  local blkdata = ""
  if blocks[1] ~= indat.datablock then
    table.insert(blocks, 1, indat.datablock)
  end
  for i=1, #ptrs, 1 do
    saved = saved + 1
    if saved == 511 then
      saved = 0
      blkidx = blkidx + 1
      if not blocks[blkidx] then
        blocks[blkidx] = self:_allocateBlock()
      end
      blkdata = blkdata .. string.pack("<I4", blocks[blkidx])
      self:_writeBlock(blocks[blkidx], blkdata)
      blkdata = ""
    else
      blkdata = blkdata .. string.pack("<I2", ptrs[i])
    end
  end
  if #blkdata > 0 then
    blkidx = blkidx + 1
    if not blocks[blkidx] then
      blocks[blkidx] = self:_allocateBlock()
    end
    self:_writeBlock(blocks[blkidx], blkdata)
  end
  return true
end

local function split(path)
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

local function clean(path)
  return "/" .. table.concat(split(path), "/")
end

local function getftype(fmode)
  return fmode >> 12 << 12
end

-- path -> inode number, inode data
function _fsobj:_resolve(path)
  path = clean(path)
  local root = self:_readInode(1)
  if path == "/" then
    return 1, root
  end
  local segs = split(path)
  local inodes = self:_listDirInode(root)
  for n=1, #segs, 1 do
    local resolved = false
    for i=1, #inodes, 1 do
      local node = self:_readInode(inodes[i])
      if node.filename == segs[n] then
        if i == #segs then
          return inodes[i], node
        elseif getftype(node.mode) ~= cfs.modes.f_directory then
          return nil, table.concat(segs, "/", 1, i) .. ": not a directory"
        else
          inodes = self:_listDirInode(node)
          resolved = true
          break
        end
      end
    end
    if not resolved then
      return nil, "no such file or directory"
    end
  end
end

function _fsobj:_createFile(path, mode, link)
  local __n, __inode = self:_resolve(path)
  if __n then
    return nil, path .. ": file exists"
  end
  
  local segm = split(path)
  local n, inode = self:_resolve(table.concat(segm, "/", 1, #segm - 1))
  if not n then
    return nil, inode
  end
  
  if getftype(inode.mode) ~= cfs.modes.f_directory then
    return nil, "/"..table.concat(segm, "/", 1, #segm - 1)..": not a directory"
  end
  
  local new_inode = self:_allocateInode(mode)
  local dirptrlist, blk = self:_listDirInode(inode)
  dirptrlist[#dirptrlist + 1] = new_inode
  
  self:_saveDirInode(inode, dirptrlist, blk)
  
  inode.modify = os.time()
  self:_writeInode(n, inode)
  
  local indata = {
    mode = mode,
    uid = 0,
    gid = 0,
    access = os.time(),
    create = os.time(),
    modify = os.time(),
    size = 0,
    references = 1,
    datablock = 0,
    filename = segm[#segm],
    extended_data = ""
  }
  
  local ftype = getftype(mode)
  if ftype == cfs.modes.f_symlink then
    indata.size = #link
    indata.extended_data = link
  else
    indata.size = 1024
    indata.datablock = self:_allocateBlock()
  end
  
  self:_writeInode(new_inode, indata)
  return true
end


-- -------------------------------------- --
-- actual user-level functions begin here --
-- -------------------------------------- --

function _fsobj:stat(file)
  checkArg(1, file, "string")
  local n, inode = self:_resolve(file)
  if not n then
    return nil, inode
  end
  local ftype = getftype(inode.mode)
  return {
    ino = n,
    mode = inode.mode,
    nlink = inode.references,
    uid = inode.uid,
    gid = inode.gid,
    size = inode.size,
    blksize = 1024,
    blocks = math.ceil(inode.size / 512),
    atime = inode.access,
    mtime = inode.modify,
    ctime = inode.create
  }
end

function _fsobj:mkdir(path, mode)
  checkArg(1, path, "string")
  mode = mode & 0x0fff -- remove filetype information embedded in 'mode'
  mode = mode | cfs.modes.f_directory
  return self:_createFile(path, mode)
end

function _fsobj:open(path, flags)
end

function cfs.new(drive)
  if checkArg then checkArg(1, drive, "table") end

  local new = setmetatable({drive = drive, cache = {}}, {__index = _fsobj})

  local superblock = cfs.superblock(drive.readSector(2))
  if superblock.signature ~= "\x1bCFS" then
    error "FIS contains bad filesystem signature"
  end

  new.fis = superblock

  return new
end

return cfs
