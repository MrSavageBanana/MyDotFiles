-- created with Claude. Account: Milobowler

---@param msg string
local notify_warn = function(msg)
    ya.notify { title = "Restic", content = msg, level = "warn", timeout = 5 }
end

---@param msg string
local notify_error = function(msg)
    ya.notify { title = "Restic", content = msg, level = "error", timeout = 5 }
end

---@param msg string
local notify_info = function(msg)
    ya.notify { title = "Restic", content = msg, level = "info", timeout = 5 }
end

---@return string
local get_cwd = ya.sync(function()
    return tostring(cx.active.current.cwd)
end)

---@param s string
---@return string
local trim = function(s)
    return s:match("^%s*(.-)%s*$")
end

-- Configuration
local RESTIC_REPO = os.getenv("HOME") .. "/.snapshots"
local RESTIC_MOUNT = os.getenv("HOME") .. "/restic-mount"
local RESTIC_CACHE = "/tmp/restic-snapshots-" .. os.getenv("USER") .. ".txt"

---@class Snapshot
---@field id string
---@field time string
---@field path string

---@return boolean
local function is_restic_mounted()
    local check = Command("ls")
        :arg({ "-A", RESTIC_MOUNT })
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
    
    if not check or not check.status.success then
        return false
    end
    
    return trim(check.stdout) ~= ""
end

---@return boolean
local function ensure_mount_dir()
    local stat = Command("stat")
        :arg({ RESTIC_MOUNT })
        :stderr(Command.PIPED)
        :status()
    
    if not stat or not stat.success then
        local mkdir = Command("mkdir")
            :arg({ "-p", RESTIC_MOUNT })
            :status()
        return mkdir and mkdir.success
    end
    return true
end

---@return boolean
local function mount_restic()
    if is_restic_mounted() then
        return true
    end

    if not ensure_mount_dir() then
        notify_error("Failed to create mount directory")
        return false
    end

    local permit = ya.hide()
    print("═══════════════════════════════════════════")
    print("  Mounting Restic Repository")
    print("═══════════════════════════════════════════")
    print("")
    print("Repository: " .. RESTIC_REPO)
    print("Mount point: " .. RESTIC_MOUNT)
    print("")
    print("Mounting restic - you will be prompted for password.")
    print("")
    
    local mount_cmd = string.format(
        "bash -c 'nohup restic -r %s mount %s </dev/tty >/dev/null 2>&1 &'",
        RESTIC_REPO,
        RESTIC_MOUNT
    )
    os.execute(mount_cmd)
    
    print("Waiting for mount to establish...")
    local max_wait = 20
    for i = 1, max_wait do
        os.execute("sleep 0.5")
        if is_restic_mounted() then
            print("✓ Mount successful!")
            os.execute("sleep 1")
            permit:drop()
            notify_info("Restic mounted")
            return true
        end
    end
    
    permit:drop()
    notify_error("Mount failed or timed out")
    return false
end

---@return string[]
local function get_snapshot_ids_from_mount()
    local ids_dir = RESTIC_MOUNT .. "/ids"
    
    local output = Command("ls")
        :arg({ "-1", ids_dir })
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
    
    if not output or not output.status.success then
        return {}
    end
    
    local ids = {}
    for line in output.stdout:gmatch("[^\r\n]+") do
        local id = trim(line)
        if id ~= "" then
            table.insert(ids, id)
        end
    end
    
    table.sort(ids, function(a, b) return a > b end)
    
    return ids
end

---@return Snapshot[]
local function get_snapshots_with_info()
    local permit = ya.hide()
    print("═══════════════════════════════════════════")
    print("  Fetching Snapshots")
    print("═══════════════════════════════════════════")
    print("")
    
    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
    local status = os.execute(cmd)
    
    if not (status == 0 or status == true) then
        print("Failed to fetch snapshots")
        print("Press Enter to continue...")
        io.read()
        permit:drop()
        return {}
    end
    
    local file = io.open(RESTIC_CACHE, "r")
    if not file then
        notify_error("Could not open file")
        return {}
    end
    
    local output = file:read("*a")
    file:close()
    
    if not output or output == "" then
        notify_error("Output is empty")
        return {}
    end
    
    -- Parse output
    local snapshots = {}
    local in_data = false
    
    for line in output:gmatch("[^\r\n]+") do
        if line:match("^%-+$") then
            in_data = not in_data
        elseif in_data and not line:match("^%d+%s+snapshot") then
            -- Extract ID (first 8 chars)
            local id = line:match("^(%w+)%s+")
            
            if id and #id == 8 then
                -- Extract date and time
                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                local time = line:match("%d%d:%d%d:%d%d")
                
                -- Extract path - it's the part that starts with /
                local path = line:match("(%/[^%s]+)")
                
                if date and time and path then
                    table.insert(snapshots, {
                        id = id,
                        time = date .. " " .. time,
                        path = path,
                    })
                end
            end
        end
    end
    
    permit:drop()
    
    return snapshots
end
---@return Snapshot[]
local function get_snapshots_with_info()
    local permit = ya.hide()
    print("═══════════════════════════════════════════")
    print("  Fetching Snapshots")
    print("═══════════════════════════════════════════")
    print("")
    
    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
    local status = os.execute(cmd)
    
    if not (status == 0 or status == true) then
        print("Failed to fetch snapshots")
        print("Press Enter to continue...")
        io.read()
        permit:drop()
        return {}
    end
    
    local file = io.open(RESTIC_CACHE, "r")
    if not file then
        notify_error("Could not open file")
        return {}
    end
    
    local output = file:read("*a")
    file:close()
    
    if not output or output == "" then
        notify_error("Output is empty")
        return {}
    end
    
    -- Parse output
    local snapshots = {}
    local in_data = false
    
    for line in output:gmatch("[^\r\n]+") do
        if line:match("^%-+$") then
            in_data = not in_data
        elseif in_data and not line:match("^%d+%s+snapshot") then
            -- Extract ID (first 8 chars)
            local id = line:match("^(%w+)%s+")
            
            if id and #id == 8 then
                -- Extract date and time
                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                local time = line:match("%d%d:%d%d:%d%d")
                
                -- Extract path - it's the part that starts with /
                local path = line:match("(%/[^%s]+)")
                
                if date and time and path then
                    table.insert(snapshots, {
                        id = id,
                        time = date .. " " .. time,
                        path = path,
                    })
                end
            end
        end
    end
    
    permit:drop()
    
    return snapshots
end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                    local function get_snapshots_with_info()
                        local permit = ya.hide()
                        print("═══════════════════════════════════════════")
                        print("  Fetching Snapshots")
                        print("═══════════════════════════════════════════")
                        print("")
                        
                        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                        local status = os.execute(cmd)
                        
                        if not (status == 0 or status == true) then
                            print("Failed to fetch snapshots")
                            print("Press Enter to continue...")
                            io.read()
                            permit:drop()
                            return {}
                        end
                        
                        local file = io.open(RESTIC_CACHE, "r")
                        if not file then
                            notify_error("Could not open file")
                            return {}
                        end
                        
                        local output = file:read("*a")
                        file:close()
                        
                        if not output or output == "" then
                            notify_error("Output is empty")
                            return {}
                        end
                        
                        -- Parse output
                        local snapshots = {}
                        local in_data = false
                        
                        for line in output:gmatch("[^\r\n]+") do
                            if line:match("^%-+$") then
                                in_data = not in_data
                            elseif in_data and not line:match("^%d+%s+snapshot") then
                                -- Extract ID (first 8 chars)
                                local id = line:match("^(%w+)%s+")
                                
                                if id and #id == 8 then
                                    -- Extract date and time
                                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                    local time = line:match("%d%d:%d%d:%d%d")
                                    
                                    -- Extract path - it's the part that starts with /
                                    local path = line:match("(%/[^%s]+)")
                                    
                                    if date and time and path then
                                        table.insert(snapshots, {
                                            id = id,
                                            time = date .. " " .. time,
                                            path = path,
                                        })
                                    end
                                end
                            end
                        end
                        
                        permit:drop()
                        
                        return snapshots
                    end
---@return Snapshot[]
                    local function get_snapshots_with_info()
                        local permit = ya.hide()
                        print("═══════════════════════════════════════════")
                        print("  Fetching Snapshots")
                        print("═══════════════════════════════════════════")
                        print("")
                        
                        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                        local status = os.execute(cmd)
                        
                        if not (status == 0 or status == true) then
                            print("Failed to fetch snapshots")
                            print("Press Enter to continue...")
                            io.read()
                            permit:drop()
                            return {}
                        end
                        
                        local file = io.open(RESTIC_CACHE, "r")
                        if not file then
                            notify_error("Could not open file")
                            return {}
                        end
                        
                        local output = file:read("*a")
                        file:close()
                        
                        if not output or output == "" then
                            notify_error("Output is empty")
                            return {}
                        end
                        
                        -- Parse output
                        local snapshots = {}
                        local in_data = false
                        
                        for line in output:gmatch("[^\r\n]+") do
                            if line:match("^%-+$") then
                                in_data = not in_data
                            elseif in_data and not line:match("^%d+%s+snapshot") then
                                -- Extract ID (first 8 chars)
                                local id = line:match("^(%w+)%s+")
                                
                                if id and #id == 8 then
                                    -- Extract date and time
                                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                    local time = line:match("%d%d:%d%d:%d%d")
                                    
                                    -- Extract path - it's the part that starts with /
                                    local path = line:match("(%/[^%s]+)")
                                    
                                    if date and time and path then
                                        table.insert(snapshots, {
                                            id = id,
                                            time = date .. " " .. time,
                                            path = path,
                                        })
                                    end
                                end
                            end
                        end
                        
                        permit:drop()
                        
                        return snapshots
                    end
---@return Snapshot[]
                        local function get_snapshots_with_info()
                            local permit = ya.hide()
                            print("═══════════════════════════════════════════")
                            print("  Fetching Snapshots")
                            print("═══════════════════════════════════════════")
                            print("")
                            
                            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                            local status = os.execute(cmd)
                            
                            if not (status == 0 or status == true) then
                                print("Failed to fetch snapshots")
                                print("Press Enter to continue...")
                                io.read()
                                permit:drop()
                                return {}
                            end
                            
                            local file = io.open(RESTIC_CACHE, "r")
                            if not file then
                                notify_error("Could not open file")
                                return {}
                            end
                            
                            local output = file:read("*a")
                            file:close()
                            
                            if not output or output == "" then
                                notify_error("Output is empty")
                                return {}
                            end
                            
                            -- Parse output
                            local snapshots = {}
                            local in_data = false
                            
                            for line in output:gmatch("[^\r\n]+") do
                                if line:match("^%-+$") then
                                    in_data = not in_data
                                elseif in_data and not line:match("^%d+%s+snapshot") then
                                    -- Extract ID (first 8 chars)
                                    local id = line:match("^(%w+)%s+")
                                    
                                    if id and #id == 8 then
                                        -- Extract date and time
                                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                        local time = line:match("%d%d:%d%d:%d%d")
                                        
                                        -- Extract path - it's the part that starts with /
                                        local path = line:match("(%/[^%s]+)")
                                        
                                        if date and time and path then
                                            table.insert(snapshots, {
                                                id = id,
                                                time = date .. " " .. time,
                                                path = path,
                                            })
                                        end
                                    end
                                end
                            end
                            
                            permit:drop()
                            
                            return snapshots
                        end
---@return Snapshot[]
                        local function get_snapshots_with_info()
                            local permit = ya.hide()
                            print("═══════════════════════════════════════════")
                            print("  Fetching Snapshots")
                            print("═══════════════════════════════════════════")
                            print("")
                            
                            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                            local status = os.execute(cmd)
                            
                            if not (status == 0 or status == true) then
                                print("Failed to fetch snapshots")
                                print("Press Enter to continue...")
                                io.read()
                                permit:drop()
                                return {}
                            end
                            
                            local file = io.open(RESTIC_CACHE, "r")
                            if not file then
                                notify_error("Could not open file")
                                return {}
                            end
                            
                            local output = file:read("*a")
                            file:close()
                            
                            if not output or output == "" then
                                notify_error("Output is empty")
                                return {}
                            end
                            
                            -- Parse output
                            local snapshots = {}
                            local in_data = false
                            
                            for line in output:gmatch("[^\r\n]+") do
                                if line:match("^%-+$") then
                                    in_data = not in_data
                                elseif in_data and not line:match("^%d+%s+snapshot") then
                                    -- Extract ID (first 8 chars)
                                    local id = line:match("^(%w+)%s+")
                                    
                                    if id and #id == 8 then
                                        -- Extract date and time
                                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                        local time = line:match("%d%d:%d%d:%d%d")
                                        
                                        -- Extract path - it's the part that starts with /
                                        local path = line:match("(%/[^%s]+)")
                                        
                                        if date and time and path then
                                            table.insert(snapshots, {
                                                id = id,
                                                time = date .. " " .. time,
                                                path = path,
                                            })
                                        end
                                    end
                                end
                            end
                            
                            permit:drop()
                            
                            return snapshots
                        end
---@return Snapshot[]
                        local function get_snapshots_with_info()
                            local permit = ya.hide()
                            print("═══════════════════════════════════════════")
                            print("  Fetching Snapshots")
                            print("═══════════════════════════════════════════")
                            print("")
                            
                            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                            local status = os.execute(cmd)
                            
                            if not (status == 0 or status == true) then
                                print("Failed to fetch snapshots")
                                print("Press Enter to continue...")
                                io.read()
                                permit:drop()
                                return {}
                            end
                            
                            local file = io.open(RESTIC_CACHE, "r")
                            if not file then
                                notify_error("Could not open file")
                                return {}
                            end
                            
                            local output = file:read("*a")
                            file:close()
                            
                            if not output or output == "" then
                                notify_error("Output is empty")
                                return {}
                            end
                            
                            -- Parse output
                            local snapshots = {}
                            local in_data = false
                            
                            for line in output:gmatch("[^\r\n]+") do
                                if line:match("^%-+$") then
                                    in_data = not in_data
                                elseif in_data and not line:match("^%d+%s+snapshot") then
                                    -- Extract ID (first 8 chars)
                                    local id = line:match("^(%w+)%s+")
                                    
                                    if id and #id == 8 then
                                        -- Extract date and time
                                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                        local time = line:match("%d%d:%d%d:%d%d")
                                        
                                        -- Extract path - it's the part that starts with /
                                        local path = line:match("(%/[^%s]+)")
                                        
                                        if date and time and path then
                                            table.insert(snapshots, {
                                                id = id,
                                                time = date .. " " .. time,
                                                path = path,
                                            })
                                        end
                                    end
                                end
                            end
                            
                            permit:drop()
                            
                            return snapshots
                        end
---@return Snapshot[]
                    local function get_snapshots_with_info()
                        local permit = ya.hide()
                        print("═══════════════════════════════════════════")
                        print("  Fetching Snapshots")
                        print("═══════════════════════════════════════════")
                        print("")
                        
                        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                        local status = os.execute(cmd)
                        
                        if not (status == 0 or status == true) then
                            print("Failed to fetch snapshots")
                            print("Press Enter to continue...")
                            io.read()
                            permit:drop()
                            return {}
                        end
                        
                        local file = io.open(RESTIC_CACHE, "r")
                        if not file then
                            notify_error("Could not open file")
                            return {}
                        end
                        
                        local output = file:read("*a")
                        file:close()
                        
                        if not output or output == "" then
                            notify_error("Output is empty")
                            return {}
                        end
                        
                        -- Parse output
                        local snapshots = {}
                        local in_data = false
                        
                        for line in output:gmatch("[^\r\n]+") do
                            if line:match("^%-+$") then
                                in_data = not in_data
                            elseif in_data and not line:match("^%d+%s+snapshot") then
                                -- Extract ID (first 8 chars)
                                local id = line:match("^(%w+)%s+")
                                
                                if id and #id == 8 then
                                    -- Extract date and time
                                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                    local time = line:match("%d%d:%d%d:%d%d")
                                    
                                    -- Extract path - it's the part that starts with /
                                    local path = line:match("(%/[^%s]+)")
                                    
                                    if date and time and path then
                                        table.insert(snapshots, {
                                            id = id,
                                            time = date .. " " .. time,
                                            path = path,
                                        })
                                    end
                                end
                            end
                        end
                        
                        permit:drop()
                        
                        return snapshots
                    end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
                    local function get_snapshots_with_info()
                        local permit = ya.hide()
                        print("═══════════════════════════════════════════")
                        print("  Fetching Snapshots")
                        print("═══════════════════════════════════════════")
                        print("")
                        
                        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                        local status = os.execute(cmd)
                        
                        if not (status == 0 or status == true) then
                            print("Failed to fetch snapshots")
                            print("Press Enter to continue...")
                            io.read()
                            permit:drop()
                            return {}
                        end
                        
                        local file = io.open(RESTIC_CACHE, "r")
                        if not file then
                            notify_error("Could not open file")
                            return {}
                        end
                        
                        local output = file:read("*a")
                        file:close()
                        
                        if not output or output == "" then
                            notify_error("Output is empty")
                            return {}
                        end
                        
                        -- Parse output
                        local snapshots = {}
                        local in_data = false
                        
                        for line in output:gmatch("[^\r\n]+") do
                            if line:match("^%-+$") then
                                in_data = not in_data
                            elseif in_data and not line:match("^%d+%s+snapshot") then
                                -- Extract ID (first 8 chars)
                                local id = line:match("^(%w+)%s+")
                                
                                if id and #id == 8 then
                                    -- Extract date and time
                                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                    local time = line:match("%d%d:%d%d:%d%d")
                                    
                                    -- Extract path - it's the part that starts with /
                                    local path = line:match("(%/[^%s]+)")
                                    
                                    if date and time and path then
                                        table.insert(snapshots, {
                                            id = id,
                                            time = date .. " " .. time,
                                            path = path,
                                        })
                                    end
                                end
                            end
                        end
                        
                        permit:drop()
                        
                        return snapshots
                    end
---@return Snapshot[]
                local function get_snapshots_with_info()
                    local permit = ya.hide()
                    print("═══════════════════════════════════════════")
                    print("  Fetching Snapshots")
                    print("═══════════════════════════════════════════")
                    print("")
                    
                    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                    local status = os.execute(cmd)
                    
                    if not (status == 0 or status == true) then
                        print("Failed to fetch snapshots")
                        print("Press Enter to continue...")
                        io.read()
                        permit:drop()
                        return {}
                    end
                    
                    local file = io.open(RESTIC_CACHE, "r")
                    if not file then
                        notify_error("Could not open file")
                        return {}
                    end
                    
                    local output = file:read("*a")
                    file:close()
                    
                    if not output or output == "" then
                        notify_error("Output is empty")
                        return {}
                    end
                    
                    -- Parse output
                    local snapshots = {}
                    local in_data = false
                    
                    for line in output:gmatch("[^\r\n]+") do
                        if line:match("^%-+$") then
                            in_data = not in_data
                        elseif in_data and not line:match("^%d+%s+snapshot") then
                            -- Extract ID (first 8 chars)
                            local id = line:match("^(%w+)%s+")
                            
                            if id and #id == 8 then
                                -- Extract date and time
                                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                                local time = line:match("%d%d:%d%d:%d%d")
                                
                                -- Extract path - it's the part that starts with /
                                local path = line:match("(%/[^%s]+)")
                                
                                if date and time and path then
                                    table.insert(snapshots, {
                                        id = id,
                                        time = date .. " " .. time,
                                        path = path,
                                    })
                                end
                            end
                        end
                    end
                    
                    permit:drop()
                    
                    return snapshots
                end
---@return Snapshot[]
            local function get_snapshots_with_info()
                local permit = ya.hide()
                print("═══════════════════════════════════════════")
                print("  Fetching Snapshots")
                print("═══════════════════════════════════════════")
                print("")
                
                local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
                local status = os.execute(cmd)
                
                if not (status == 0 or status == true) then
                    print("Failed to fetch snapshots")
                    print("Press Enter to continue...")
                    io.read()
                    permit:drop()
                    return {}
                end
                
                local file = io.open(RESTIC_CACHE, "r")
                if not file then
                    notify_error("Could not open file")
                    return {}
                end
                
                local output = file:read("*a")
                file:close()
                
                if not output or output == "" then
                    notify_error("Output is empty")
                    return {}
                end
                
                -- Parse output
                local snapshots = {}
                local in_data = false
                
                for line in output:gmatch("[^\r\n]+") do
                    if line:match("^%-+$") then
                        in_data = not in_data
                    elseif in_data and not line:match("^%d+%s+snapshot") then
                        -- Extract ID (first 8 chars)
                        local id = line:match("^(%w+)%s+")
                        
                        if id and #id == 8 then
                            -- Extract date and time
                            local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                            local time = line:match("%d%d:%d%d:%d%d")
                            
                            -- Extract path - it's the part that starts with /
                            local path = line:match("(%/[^%s]+)")
                            
                            if date and time and path then
                                table.insert(snapshots, {
                                    id = id,
                                    time = date .. " " .. time,
                                    path = path,
                                })
                            end
                        end
                    end
                end
                
                permit:drop()
                
                return snapshots
            end
---@return Snapshot[]
        local function get_snapshots_with_info()
            local permit = ya.hide()
            print("═══════════════════════════════════════════")
            print("  Fetching Snapshots")
            print("═══════════════════════════════════════════")
            print("")
            
            local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
            local status = os.execute(cmd)
            
            if not (status == 0 or status == true) then
                print("Failed to fetch snapshots")
                print("Press Enter to continue...")
                io.read()
                permit:drop()
                return {}
            end
            
            local file = io.open(RESTIC_CACHE, "r")
            if not file then
                notify_error("Could not open file")
                return {}
            end
            
            local output = file:read("*a")
            file:close()
            
            if not output or output == "" then
                notify_error("Output is empty")
                return {}
            end
            
            -- Parse output
            local snapshots = {}
            local in_data = false
            
            for line in output:gmatch("[^\r\n]+") do
                if line:match("^%-+$") then
                    in_data = not in_data
                elseif in_data and not line:match("^%d+%s+snapshot") then
                    -- Extract ID (first 8 chars)
                    local id = line:match("^(%w+)%s+")
                    
                    if id and #id == 8 then
                        -- Extract date and time
                        local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                        local time = line:match("%d%d:%d%d:%d%d")
                        
                        -- Extract path - it's the part that starts with /
                        local path = line:match("(%/[^%s]+)")
                        
                        if date and time and path then
                            table.insert(snapshots, {
                                id = id,
                                time = date .. " " .. time,
                                path = path,
                            })
                        end
                    end
                end
            end
            
            permit:drop()
            
            return snapshots
        end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
    local function get_snapshots_with_info()
        local permit = ya.hide()
        print("═══════════════════════════════════════════")
        print("  Fetching Snapshots")
        print("═══════════════════════════════════════════")
        print("")
        
        local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
        local status = os.execute(cmd)
        
        if not (status == 0 or status == true) then
            print("Failed to fetch snapshots")
            print("Press Enter to continue...")
            io.read()
            permit:drop()
            return {}
        end
        
        local file = io.open(RESTIC_CACHE, "r")
        if not file then
            notify_error("Could not open file")
            return {}
        end
        
        local output = file:read("*a")
        file:close()
        
        if not output or output == "" then
            notify_error("Output is empty")
            return {}
        end
        
        -- Parse output
        local snapshots = {}
        local in_data = false
        
        for line in output:gmatch("[^\r\n]+") do
            if line:match("^%-+$") then
                in_data = not in_data
            elseif in_data and not line:match("^%d+%s+snapshot") then
                -- Extract ID (first 8 chars)
                local id = line:match("^(%w+)%s+")
                
                if id and #id == 8 then
                    -- Extract date and time
                    local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                    local time = line:match("%d%d:%d%d:%d%d")
                    
                    -- Extract path - it's the part that starts with /
                    local path = line:match("(%/[^%s]+)")
                    
                    if date and time and path then
                        table.insert(snapshots, {
                            id = id,
                            time = date .. " " .. time,
                            path = path,
                        })
                    end
                end
            end
        end
        
        permit:drop()
        
        return snapshots
    end
---@return Snapshot[]
local function get_snapshots_with_info()
    local permit = ya.hide()
    print("═══════════════════════════════════════════")
    print("  Fetching Snapshots")
    print("═══════════════════════════════════════════")
    print("")
    
    local cmd = string.format("restic -r %s snapshots > %s 2>&1", RESTIC_REPO, RESTIC_CACHE)
    local status = os.execute(cmd)
    
    if not (status == 0 or status == true) then
        print("Failed to fetch snapshots")
        print("Press Enter to continue...")
        io.read()
        permit:drop()
        return {}
    end
    
    local file = io.open(RESTIC_CACHE, "r")
    if not file then
        notify_error("Could not open file")
        return {}
    end
    
    local output = file:read("*a")
    file:close()
    
    if not output or output == "" then
        notify_error("Output is empty")
        return {}
    end
    
    -- Parse output
    local snapshots = {}
    local in_data = false
    
    for line in output:gmatch("[^\r\n]+") do
        if line:match("^%-+$") then
            in_data = not in_data
        elseif in_data and not line:match("^%d+%s+snapshot") then
            -- Extract ID (first 8 chars)
            local id = line:match("^(%w+)%s+")
            
            if id and #id == 8 then
                -- Extract date and time
                local date = line:match("%d%d%d%d%-%d%d%-%d%d")
                local time = line:match("%d%d:%d%d:%d%d")
                
                -- Extract path - it's the part that starts with /
                local path = line:match("(%/[^%s]+)")
                
                if date and time and path then
                    table.insert(snapshots, {
                        id = id,
                        time = date .. " " .. time,
                        path = path,
                    })
                end
            end
        end
    end
    
    permit:drop()
    
    return snapshots
end

---@param cwd string
---@return boolean, string|nil, string|nil
local function is_in_mount(cwd)
    if cwd:sub(1, #RESTIC_MOUNT) == RESTIC_MOUNT then
        local pattern = RESTIC_MOUNT .. "/ids/([^/]+)(/.*)$"
        local snapshot_id, subpath = cwd:match(pattern)
        return true, snapshot_id, subpath
    end
    return false, nil, nil
end

---@param snapshot_id string
---@param path string
---@return string
local function get_snapshot_path(snapshot_id, path)
    return RESTIC_MOUNT .. "/ids/" .. snapshot_id .. path
end

---@param path string
---@return boolean
local function path_exists(path)
    local stat = Command("stat")
        :arg({ path })
        :stderr(Command.PIPED)
        :status()
    return stat and stat.success
end

---@param original_cwd string
local function take_snapshot(original_cwd)
    local permit = ya.hide()
    print("═══════════════════════════════════════════")
    print("  Taking Restic Snapshot")
    print("═══════════════════════════════════════════")
    print("")
    print("Path: " .. original_cwd)
    print("Repository: " .. RESTIC_REPO)
    print("")
    print("You will be prompted for your restic password.")
    print("")
    
    local cmd = string.format("restic -r %s backup %s", RESTIC_REPO, original_cwd)
    local status = os.execute(cmd)
    
    print("")
    if status == 0 or status == true then
        print("✓ Snapshot created successfully!")
        os.execute("sleep 1")
        permit:drop()
        notify_info("Snapshot created")
    else
        print("✗ Snapshot failed")
        print("Press Enter to continue...")
        io.read()
        permit:drop()
        notify_error("Snapshot failed")
    end
end

---@param snapshots Snapshot[]
local function show_snapshot_list(snapshots)
    if #snapshots == 0 then
        return notify_warn("No snapshots found")
    end

    local permit = ya.hide()
    print("   Time                   Paths")
    print("   ----------------------------------------------")
    
    for i, snapshot in ipairs(snapshots) do
        print(string.format("%d. %-20s %s", i, snapshot.time, snapshot.path))
    end
    
    print("   ----------------------------------------------")
    print("")
    print("Enter number: ")
    local input = io.read()
    permit:drop()

    local choice = tonumber(input)
    if choice and choice >= 1 and choice <= #snapshots then
        local snapshot = snapshots[choice]
        
        if not mount_restic() then
            return notify_error("Failed to mount restic")
        end
        
        local path = get_snapshot_path(snapshot.id, snapshot.path)
        
        if path_exists(path) then
            ya.manager_emit("cd", { path })
        else
            notify_warn("Path doesn't exist in snapshot")
        end
    end
end

return {
    entry = function(_, job)
        local action = job.args[1]
        
        if not action then
            return notify_error("No action specified")
        end

        if action ~= "exit" and action ~= "prev" and action ~= "next" and 
           action ~= "list" and action ~= "snapshot" then
            return notify_error("Invalid action: " .. action)
        end

        local cwd = get_cwd()
        local in_mount, current_snapshot_id, current_subpath = is_in_mount(cwd)
        
        local original_cwd
        if in_mount then
            original_cwd = current_subpath
        else
            original_cwd = cwd
        end

        if action == "snapshot" then
            if in_mount then
                return notify_warn("Exit snapshot view first")
            end
            return take_snapshot(original_cwd)
        end

        if action == "exit" then
            if in_mount then
                ya.manager_emit("cd", { original_cwd })
            end
            return
        end

        if action == "list" then
            local snapshots = get_snapshots_with_info()
            if #snapshots == 0 then
                return notify_warn("No snapshots found")
            end
            return show_snapshot_list(snapshots)
        end

        if not mount_restic() then
            return
        end
        
        local snapshot_ids = get_snapshot_ids_from_mount()
        
        if #snapshot_ids == 0 then
            return notify_warn("No snapshots found in mount")
        end

        if not in_mount then
            if action == "prev" then
                local path = get_snapshot_path(snapshot_ids[1], original_cwd)
                if path_exists(path) then
                    ya.manager_emit("cd", { path })
                else
                    notify_warn("Path doesn't exist in newest snapshot")
                end
            elseif action == "next" then
                notify_warn("Already at current state (newest)")
            end
        else
            local idx = nil
            for i, id in ipairs(snapshot_ids) do
                if id:sub(1, 8) == current_snapshot_id or id == current_snapshot_id then
                    idx = i
                    break
                end
            end
            
            if not idx then
                return notify_error("Current snapshot not found")
            end

            if action == "prev" then
                if idx + 1 <= #snapshot_ids then
                    local path = get_snapshot_path(snapshot_ids[idx + 1], original_cwd)
                    if path_exists(path) then
                        ya.manager_emit("cd", { path })
                    else
                        notify_warn("Path doesn't exist in that snapshot")
                    end
                else
                    notify_warn("No older snapshots")
                end
            elseif action == "next" then
                if idx == 1 then
                    ya.manager_emit("cd", { original_cwd })
                else
                    local path = get_snapshot_path(snapshot_ids[idx - 1], original_cwd)
                    if path_exists(path) then
                        ya.manager_emit("cd", { path })
                    else
                        notify_warn("Path doesn't exist in that snapshot")
                    end
                end
            end
        end
    end,
}
