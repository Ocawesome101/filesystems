local cfs = require("cfs")

local node = cfs.new(require("component").drive)

local root = node:stat("/")

print "stat /"
for k, v in pairs(root) do print(k,v) end
