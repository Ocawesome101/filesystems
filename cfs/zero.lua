-- completely zero a drive.  may fix some issues. --

local drive = require("component").drive

print("zeroing drive")

local sectors = drive.getCapacity() / 512
local written = 0
local width = 40
local zero = ("\0"):rep(512)

io.write("\n")
for i=1, sectors, 1 do
  io.write("\27[A", math.floor(written / sectors * 100), "% ",
    ("#"):rep(math.floor(written / sectors * width)), "\n")
  written = written + 1
  drive.writeSector(i, zero)
end

print("done")
