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
