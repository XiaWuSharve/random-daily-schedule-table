-- local SKIN

local function map(table, fun)
    local res = {}
    local p
    if type(table) == "table" then
        p = function (t)
            return pairs(t)
        end
    else
        p = function (t)
            local i = 0
            return function ()
                local v = t()
                i = i + 1
                if v then
                    return i, v
                end
            end
        end
    end
    for index, value in p(table) do
        res[index] = fun(value)
    end
    return res
end

local function parseTime(str)
    local iter = string.gmatch(str, '(%d+)')
    local nums = map(iter, tonumber)
    local date = {year=nums[1], month=nums[2], day=nums[3], hour=nums[4], min=nums[5]}
    return os.time(date)
end

local function loadData(filename, tableName)
    local lines = {}
    local iter = io.lines(filename)
    for line in iter do
        if line == tableName then
            iter()
            break
        end
    end
    for line in iter do
        if not string.match(line, '(%s)') then
            break
        end
        lines[#lines+1] = line
    end
    return lines
end

local function genTable(outputPath)
    local filename = SKIN:ReplaceVariables(SKIN:GetVariable('TablePath'))
    local tableName = SKIN:GetVariable('TableName', 'default')
    local lines = loadData(filename, tableName)

    local file = io.open(outputPath, "w+")
    io.output(file)
    for _, line in pairs(lines) do
        local iter = string.gmatch(line, '([^%s]+)')
        local units = map(iter, tostring)
        local time = table.remove(units, 1)
        local choosen = units[math.random(#units)]
        io.write(time, ' ', choosen, '\n')
    end
    io.close(file)
end

function Initialize()
    math.randomseed(os.time())
    local lastUpdateTime = SKIN:GetVariable('LastUpdateTime', '1970-1-2 0:0')
    local parsedLastUpdateTime = parseTime(lastUpdateTime)
    local curDate = os.date('*t')
    local threshhold = os.time({year=curDate['year'], month=curDate['month'], day=curDate['day'], hour=5})
    if parsedLastUpdateTime < threshhold then
        genTable(SKIN:ReplaceVariables(SKIN:GetVariable('OutputPath')))
        SKIN:Bang('!WriteKeyValue', 'Variables', 'LastUpdateTime', os.date('%Y-%m-%d %H:%M'))
    end
end