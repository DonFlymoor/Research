local bench = require("lua/console/bananabench")

--dump(args)

local outputFilename = 'bananabench.json'

if args and #args > 1 then
    outputFilename = args[2]
end

local res = bench.physics()
--dump(res)
jsonWriteFile(outputFilename, res, true)
