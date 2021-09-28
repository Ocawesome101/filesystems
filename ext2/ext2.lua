--[[
    An implementation of the Second Extended
    Filesystem for OpenComputers.  Only supports
    1KB block sizes.

    Copyright (c) 2021 Ocawesome101 under the DSLv2.
    
    ]]--

local _ = require("struct")
local struct = _.struct

local creators = {
  [0] = "linux",
  [1] = "hurd",
  [2] = "masix",
  [3] = "freebsd",
  [4] = "lites",
  -- claiming this one
  [5] = "ext2-lua"
}

local superblock = struct {
  _.uint32 "inodes_count",
  _.uint32 "blocks_count",
  _.uint32 "r_blocks_count",
  _.uint32 "free_blocks_count",
  _.uint32 "free_inodes_count",
  _.uint32 "first_data_block",
  _.uint32 "log_block_size",
  _.uint32 "log_frag_size",
  _.uint32 "blocks_per_group",
  _.uint32 "frags_per_group",
  _.uint32 "inodes_per_group",
  _.uint32 "mtime",
  _.uint32 "wtime",
  _.uint16 "mnt_count",
  _.uint16 "max_mnt_count",
  _.uint16 "magic",
  _.uint16 "state",
  _.uint16 "errors",
  _.uint16 "minor_rev_level",
  _.uint32 "lastcheck",
  _.uint32 "checkinterval",
  _.uint32 "creator_os",
  _.uint32 "rev_level",
  _.uint16 "def_resuid",
  _.uint16 "def_resgid",
  _.uint32 "first_ino",
  _.uint16 "inode_size",
  _.uint16 "block_group_nr",
  _.uint32 "feature_compat",
  _.uint32 "feature_incompat",
  _.uint32 "feature_ro_compat",
  _.char[16] "uuid",
  _.char[16] "volume_name",
  _.char[64] "last_mounted",
  _.uint32 "algo_bitmap",
  _.uint8 "prealloc_blocks",
  _.uint8 "prealloc_dir_blocks",
}

local block_group_descriptor = struct {
  _.uint32 "block_bitmap",
  _.uint32 "inode_bitmap",
  _.uint32 "inode_table",
  _.uint16 "free_blocks_count",
  _.uint16 "free_inodes_count",
  _.uint16 "used_dirs_count",
  _.uint16 "pad",
  _.char[12] "reserved"
}

local inode = struct {
  _.uint16 "mode",
  _.uint16 "uid",
  _.uint32 "size",
  _.uint32 "atime",
  _.uint32 "ctime",
  _.uint32 "mtime",
  _.uint32 "dtime",
  _.uint16 "gid",
  _.uint16 "links_count",
  _.uint32 "blocks",
  _.uint32 "flags",
  _.uint32 "osd1",
  _.char[15*4] "block",
  _.uint32 "generation",
  _.uint32 "file_acl",
  _.uint32 "dir_acl",
  _.uint32 "faddr",
  _.char[12] "osd2",
}

local _fsobj = {}

-- read a raw block from the drive.  
function _fsobj:_readRawBlock(n)
  n = n + 1
  local n_sectors_per_block = math.ceil(self.blockSize / self.sectorSize)
  local sect_offset = n_sectors_per_block * (n - 1)
  local data = ""
  for i=1, n_sectors_per_block, 1 do
    data = data .. self.drive.readSector(sect_offset + i)
  end
  return data
end

function _fsobj:_readInode(n)
  local bgroup = (n - 1) // self.superblock.inodes_per_group
  local iidx = (n - 1) % self.superblock.inodes_per_group
end

function _fsobj:_readBlockGroupDescriptors()
  local first = self:_readRawBlock(2)
  
end

local function new(drive)
  if checkArg then checkArg(1, drive, "table") end
  local new = setmetatable({
    drive = drive,
    sectorSize = drive.getSectorSize(),
    capacity = drive.getCapacity(),
    blockSize = 1024
  }, {__index = _fsobj})
  
  local sblk = superblock(new:_readRawBlock(1))
  
  sblk.uuid = sblk.uuid
    --convert to hex
    :gsub(".", function(a) return ("%02x"):format(a:byte()) end)
    -- convert to traditional UUID form
    :gsub("(........)(....)(....)(....)(.+)", "%1-%2-%3-%4-%5")
  
  new.superblock = sblk
  new.blockSize = 1024 << sblk.log_block_size
  
  print(sblk.feature_compat, sblk.feature_incompat, sblk.feature_ro_compat)
  print(sblk.first_ino, sblk.inode_size)
  print(sblk.blocks_per_group, sblk.inodes_per_group)

  new.features = {
    sparse_superblock = sblk.feature_ro_compat & 0x0001 ~= 0,
    large_file = sblk.feature_ro_compat & 0x0002 ~= 0,
    
    dir_prealloc = sblk.feature_compat & 0x0001 ~= 0,
    imagic_inodes = sblk.feature_compat & 0x0002 ~= 0,
    has_journal = sblk.feature_compat & 0x0004 ~= 0,
    extended_attributes = sblk.feature_compat & 0x0008 ~= 0,
    nonstandard_inodes = sblk.feature_compat & 0x0010 ~= 0,
    directory_indexing = sblk.feature_compat & 0x0020 ~= 0
  }

  for k, v in pairs(new.features) do print(k,v) end
 
  -- these i cannot mount if i don't support
  assert(sblk.feature_incompat & 0x0001 == 0,
    "EXT2_FEATURE_COMPRESSION unsupported")
  assert(sblk.feature_incompat & 0x0004 == 0,
    "EXT2_FEATURE_RECOVER unsupported")
  assert(sblk.feature_incompat & 0x0008 == 0,
    "EXT2_FEATURE_JOURNAL_DEV unsupported")
  assert(sblk.feature_incompat & 0x00010 == 0,
    "EXT2_FEATURE_META_BG unsupported")
  -- according to the spec we can just mount as read-only here;  i may implement
  -- that in the future, but for now i'll just error
  assert(sblk.feature_ro_compat & 0x0004 == 0,
    "EXT2_FEATURE_BINTREE_DIR unsupported") 
  
  new:_readBlockGroupDescriptors()
  return new
end

return new
