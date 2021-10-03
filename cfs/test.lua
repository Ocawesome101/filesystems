local cfs = require("cfs")

local node = cfs.new(require("component").drive)

local root = node:stat("/")

print "stat /"
for k, v in pairs(root) do print(k,v) end

print "create /bin"
print(node:_createFile("/bin", cfs.modes.f_directory))
local bin = node:stat "/bin"
if not bin then
  print("ERROR: /bin NOT CREATED")
else
  print "stat /bin"
  for k,v in pairs(bin) do
    print(k,v)
  end
end

print("create /bin/test")
local fd = assert(node:open("/bin/test", {wronly = true, creat = true,
  trunc = false},
  cfs.modes.f_regular | cfs.modes.ownerr | cfs.modes.ownerw))
print("write", node:write(fd, "this is a test\n"))
print("close", node:close(fd))

print "stat /bin/test"
local test = assert(node:stat("/bin/test"))
for k,v in pairs(test) do
  print(k,v)
end

print("read from /bin/test")
local fd = assert(node:open("/bin/test", {rdonly = true}))
repeat
  local data = node:read(fd, math.huge)
  io.write(data or "")
until not data
print("close", node:close(fd))
