local cfs = require("cfs")

local node = cfs.new(require("component").drive)

local root = node:stat("/")

print "stat /"
for k, v in pairs(root) do print(k,v) end

print "stat /bin"
local bin = node:stat "/bin"
if not bin then
  print "create /bin"
  print(node:_createFile("/bin", cfs.modes.f_directory))
  bin = node:stat "/bin"
end
if not bin then
  print("ERROR: /bin NOT CREATED")
else
  for k,v in pairs(bin) do
    print(k,v)
  end
end
