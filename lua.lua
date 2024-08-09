-- local SKIN

local function map(table, fun)
    local res = {}
    local p
    if type(table) == "table" then
        p = function(t)
            return pairs(t)
        end
    else
        p = function(t)
            local i = 0
            return function()
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
    if #nums == 0 then
        return nil
    end
    local date = {
        hour = nums[1],
        min = nums[2],
        year = nums[3] or os.date('*t').year,
        month = nums[4] or os.date('*t').month,
        day = nums[5] or (os.date('*t').day + (nums[1] < 5 and 1 or 0))
    }
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
        lines[#lines + 1] = line
    end
    return lines
end

local function lookTableEndTime(time, units)
    local iter = string.gmatch(time, '([^-]+)')
    iter()
    local endTime = iter()
    return parseTime(endTime)
end

local function genTable(time, units)
    local choosen = units[math.random(#units)]
    io.write(time, ' ', choosen, '\n')
end

local function iterateTable(fun, ...)
    local filename = SKIN:ReplaceVariables(SKIN:GetVariable('TablePath'))
    local tableName = SKIN:GetVariable('TableName', 'default')
    local lines = loadData(filename, tableName)

    local output = {}

    for _, line in pairs(lines) do
        local iter = string.gmatch(line, '([^%s]+)')
        local units = map(iter, tostring)
        local time = table.remove(units, 1)
        local ret = fun(time, units, ...)
        if ret then
            output[#output + 1] = ret
        end
    end
    return output
end

local p = 1
local endTimes

function Initialize()
    local curTime = os.time()
    math.randomseed(curTime)
    local lastUpdateTime = SKIN:GetVariable('LastUpdateTime', '0:0 1970-1-2')
    local parsedLastUpdateTime = parseTime(lastUpdateTime)
    local curDate = os.date('*t', curTime)
    local threshhold = os.time({ year = curDate['year'], month = curDate['month'], day = curDate['day'], hour = 5 })
    if parsedLastUpdateTime < threshhold then
        local outputPath = SKIN:ReplaceVariables(SKIN:GetVariable('OutputPath'))
        local file = io.open(outputPath, "w+")
        io.output(file)
        iterateTable(genTable)
        io.close(file)
        SKIN:Bang('!WriteKeyValue', 'Variables', 'LastUpdateTime', os.date('%H:%M %Y-%m-%d'))
    end
    endTimes = iterateTable(lookTableEndTime)
    p = 1
    for i, v in ipairs(endTimes) do
        if curTime < v then
            p = i
            break
        end
    end
end

function Update()
    if p == #endTimes + 1 then
        return
    end
    local script = [[
        powershell -Command "for ($var = 1; $var -le 5; $var++) { [Console]::Beep() }"
    ]]
    if os.time() > endTimes[p] then
        os.execute(script)
        p = p + 1
    end
end