local RunScriptFirst = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Translations = {
    ["Tycoon"] = "基地",
    ["Progression"] = "进阶",
    ["Performance"] = "性能",
    ["Settings"] = "设置",
    ["key"] = "密钥",
    ["Orchard"] = "果园",
    ["Auto"] = "自动",
    ["Build"] = "建造",
    ["Auto Build"] = "自动建造",
    ["Auto Progression"] = "自动进阶",
    ["Auto Buy Buttons"] = "自动买按键",
    ["Buy Needed Only"] = "只买必须的",
    ["Permanent"] = "永久",
    ["Permanent Buy"] = "永久购买",
    ["Beneficial Only"] = "（仅有益）",
    ["Permanent Buy All Buttons"] = "永久购买所有按钮",
    ["Permanent Buy Picks (optional)"] = "永久购买选择（可选）",
    ["Auto-pick (best buttons)"] = "自动购买部件",
    ["Auto Collect"] = "自动收集",
    ["Auto Collect Lemon Tree"] = "自动收集柠檬树",
    ["Lemon Tree"] = "柠檬树",
    ["Drops"] = "掉落物",
    ["Auto Collect Cash Drops"] = "自动收集现金掉落",
    ["Auto Cash Vine"] = "自动现金藤蔓",
    ["Auto Sewer Unlock"] = "自动解锁下水道",
    ["Auto Wake Income"] = "自动唤醒收入",
    ["Power Picks(optional)"] = "能力部件(选择)",
    ["Power Picks (optional)"] = "能力部件 (选择)",
    ["Upgrade Delay(s)"] = "延迟升级(秒数)",
    ["Upgrade Delay (s)"] = "延迟升级 (秒数)",
    ["Auto Upgrade Earners"] = "自动升级投资人装备",
    ["Auto Upgrade Powers"] = "自动升级摊位金钱",
    ["Harvest All Plots"] = "收获所有地块",
    ["Specific Plots (optional)"] = "指定地块（可选）",
    ["Use toggle above"] = "使用上方开关",
    ["Phone Offers"] = "手机交易",
    ["Auto Accept Offers"] = "自动接受报价",
    ["Haggle Before Accepting"] = "接受前讨价还价",
    ["Minigames (Auto-Win)"] = "小游戏（自动获胜）",
    ["Auto Lemon Dash"] = "自动柠檬冲刺",
    ["Auto Lemon Trade"] = "自动柠檬交易",
    ["Teleport"] = "传送",
    ["Destination"] = "目的地",
    ["Grow Loop"] = "种植循环",
    ["Auto Unlock Plots"] = "自动解锁地块",
    ["Auto Plant"] = "自动种植",
    ["Auto Plant Better Seed"] = "自动种植更好的种子",
    ["Auto Harvest All"] = "自动收获全部",
    ["Auto Sell Fruit"] = "自动出售水果",
    ["Mutations"] = "变异",
    ["Auto Apply Mutations"] = "自动应用变异",
    ["Replace Trees"] = "替换树木",
    ["Target Mutation (optional)"] = "目标变异（可选）",
    ["Best overall (power rating)"] = "综合最佳（能力评分）",
    ["Avoid Bad Mutations"] = "避免负面变异",
    ["Auto Replace Lesser Trees"] = "自动替换较差树木",
    ["Reroll Until Target"] = "重抽直到目标",
    ["Plot Upgrades"] = "地块升级",
    ["Upgrades to Buy (optional)"] = "要购买的升级（可选）",
    ["All upgrades"] = "全部升级",
    ["Auto Buy Plot Upgrades"] = "自动购买地块升级",
    ["Fruit Buff"] = "水果增益",
    ["Auto Eat Best Fruit"] = "自动食用最佳水果",
    ["Rebirth"] = "重生",
    ["Evolve"] = "进化",
    ["Rebirth Reward Multiplier"] = "重生奖励倍率",
    ["Min Cash Before Rebirth (0 = off)"] = "重生前最低现金（0=关闭）",
    ["Max Rebirths (0 = unlimited)"] = "最大重生次数（0=无限）",
    ["Manual"] = "手动",
    ["Ascend"] = "飞升",
    ["Rebirth Now"] = "立即重生",
    ["Ascend Now"] = "立即飞升",
    ["Evolve Now"] = "立即进化",
    ["Stop at Evolution (0 = off)"] = "进化时停止（0=关闭）",
    ["Stop at Evo Progress"] = "停止进化进度",
    ["Delay Each Rebirth"] = "每次重生延迟",
    ["Rebirth Delay (minutes)"] = "重生延迟（分钟）",
    ["Auto Rebirth"] = "自动重生",
    ["Max Evolution Level (0 = unlimited)"] = "最大进化等级（0=无限）",
    ["Auto Evolve"] = "自动进化",
    ["Auto Ascend"] = "自动飞升",
    ["Disable 3D Render"] = "禁用3D渲染",
    ["Strip Effects & Quality"] = "移除效果和降低画质",
    ["Hide Game UI"] = "隐藏游戏界面",
    ["Hide Buy Animation"] = "隐藏购买动画",
    ["Remove Popup/Cutscene"] = "移除弹窗/过场动画",
    ["Stats"] = "统计",
    ["Cash"] = "现金",
    ["Buttons Bought"] = "已购买按钮",
    ["Time Farming"] = "挂机时间",
    ["Investors"] = "投资者",
    ["Evolution"] = "进化",
    ["Ascension"] = "飞升",
    ["Overlay (fullscreen status)"] = "覆盖层（全屏状态）",
    ["Config"] = "配置",
    ["Manage"] = "管理",
    ["Transfer"] = "转移",
    ["Config Name"] = "配置名称",
    ["Saved Configs"] = "已保存配置",
    ["My config"] = "我的配置",
    ["Utility"] = "实用工具",
    ["Rejoin on Kick"] = "被踢后重新加入",
    ["Auto Execute (re-inject on rejoin)"] = "自动执行（重新加入时重新注入）",
    ["Info"] = "信息",
    ["Version"] = "版本",
    ["Game"] = "游戏",
    ["Discord"] = "Discord",
    ["Auto-Load"] = "自动加载",
    ["Save / Overwrite"] = "保存 / 覆盖",
    ["Load Selectet"] = "加载选择", -- 原脚本里的拼写错误，保留以便匹配
    ["Set as Auto-Load"] = "设置为自动加载",
    ["Clear Auto-Load"] = "清除自动加载",
    ["Delete Selected"] = "删除选择项",
    ["Load Selected"] = "加载选择",
}

------------------------------------------------------------------
-- 翻译逻辑
-- 只做"整句精确匹配"，避免短词（Auto / key / Game）误伤其他文本。
-- 另外支持 "标签: 数值" 形式（如 "Cash: 123" -> "现金: 123"）。
------------------------------------------------------------------
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function translateText(text)
    if type(text) ~= "string" or text == "" then return text end

    -- 1. 整句精确匹配
    local direct = Translations[text]
    if direct then return direct end

    -- 2. 去掉首尾空白后匹配
    local trimmed = trim(text)
    if trimmed ~= text then
        local t = Translations[trimmed]
        if t then return t end
    end

    -- 3. "标签: 数值" / "标签：数值"
    local label, sep, rest = text:match("^(.-)%s*([:：])(.*)$")
    if label and label ~= "" then
        local t = Translations[trim(label)]
        if t then return t .. sep .. rest end
    end

    return text
end

------------------------------------------------------------------
-- 漏翻检测：UI 上出现了、但翻译表里没有的英文，会集中显示在一个可复制的小窗口里
------------------------------------------------------------------
local DebugMissing = true          -- 不需要时改成 false
local reported = {}                -- 已报告过的文本（数字替换成 # 后去重）
local MissingList = {}             -- 所有漏翻文本，方便统一复制

local function isMissing(text)
    local trimmed = trim(text)
    if trimmed == "" then return false end
    if not trimmed:find("%a") then return false end            -- 纯数字/符号
    if trimmed:find("[\228-\233]") then return false end       -- 已含中文
    if Translations[trimmed] then return false end             -- 表里有（如 Discord）

    local label = trimmed:match("^(.-)%s*[:：]")
    if label and label ~= "" and Translations[trim(label)] then
        return false
    end
    return true
end

local MISSING_GUI_NAME = "EternalMissing"
local missingBox, missingTitle

local function refreshMissingUI()
    if missingBox then
        missingBox.Text = table.concat(MissingList, "\n")
    end
    if missingTitle then
        missingTitle.Text = "漏翻文本 (" .. #MissingList .. ")"
    end
end

local function reportMissing(inst, text)
    local trimmed = trim(text)
    local key = trimmed:gsub("%d+", "#")
    if reported[key] then return end
    reported[key] = true
    table.insert(MissingList, (trimmed:gsub("\n", " ")))
    refreshMissingUI()
end

local function copyMissing()
    local out = table.concat(MissingList, "\n")
    local fn = setclipboard or toclipboard
    if type(fn) == "function" then
        return pcall(fn, out)
    end
    return false
end

-- 漏翻窗口：所有漏翻英文集中显示，可拖动，可一键复制
local function createMissingUI()
    if not DebugMissing then return end

    local parent
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then parent = hui end
    end
    parent = parent or (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")) or CoreGui

    local gui = Instance.new("ScreenGui")
    gui.Name = MISSING_GUI_NAME
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 260)
    frame.Position = UDim2.new(1, -330, 0.5, -130)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    missingTitle = Instance.new("TextLabel")
    missingTitle.Size = UDim2.new(1, 0, 0, 26)
    missingTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    missingTitle.BorderSizePixel = 0
    missingTitle.Font = Enum.Font.GothamBold
    missingTitle.TextSize = 14
    missingTitle.TextColor3 = Color3.new(1, 1, 1)
    missingTitle.Text = "漏翻文本 (0)"
    missingTitle.Parent = frame

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -26)
    body.Position = UDim2.new(0, 0, 0, 26)
    body.BackgroundTransparency = 1
    body.Parent = frame

    local function makeButton(text, xScale, xOffset, wScale)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(wScale, -6, 0, 26)
        b.Position = UDim2.new(xScale, xOffset, 1, -30)
        b.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Text = text
        b.Parent = body
        return b
    end

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -38)
    scroll.Position = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = body

    missingBox = Instance.new("TextBox")
    missingBox.Size = UDim2.new(1, -6, 0, 0)
    missingBox.AutomaticSize = Enum.AutomaticSize.Y
    missingBox.BackgroundTransparency = 1
    missingBox.ClearTextOnFocus = false
    missingBox.MultiLine = true
    missingBox.TextWrapped = true
    missingBox.TextXAlignment = Enum.TextXAlignment.Left
    missingBox.TextYAlignment = Enum.TextYAlignment.Top
    missingBox.Font = Enum.Font.Code
    missingBox.TextSize = 14
    missingBox.TextColor3 = Color3.fromRGB(230, 230, 230)
    missingBox.Text = ""
    missingBox.Parent = scroll

    local copyBtn = makeButton("复制全部", 0, 4, 0.4)
    local clearBtn = makeButton("清空", 0.4, 4, 0.3)
    local hideBtn = makeButton("收起", 0.7, 4, 0.3)

    copyBtn.MouseButton1Click:Connect(function()
        local ok = copyMissing()
        copyBtn.Text = ok and "已复制 ✓" or "无法复制,请手动选中"
        task.delay(1.2, function()
            copyBtn.Text = "复制全部"
        end)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        table.clear(MissingList)
        table.clear(reported)
        refreshMissingUI()
    end)

    hideBtn.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        frame.Size = body.Visible and UDim2.new(0, 320, 0, 260) or UDim2.new(0, 320, 0, 26)
        hideBtn.Text = body.Visible and "收起" or "展开"
    end)

    refreshMissingUI()
end

local hooked = setmetatable({}, { __mode = "k" })

local function isTextElement(inst)
    return inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")
end

local function hook(inst)
    if hooked[inst] or not isTextElement(inst) then return end
    if inst:FindFirstAncestor(MISSING_GUI_NAME) then return end
    hooked[inst] = true

    local function apply()
        local current = inst.Text
        local new = translateText(current)
        if new ~= current then
            inst.Text = new -- 新文本已是中文，不会再次命中，不会死循环
        elseif DebugMissing and isMissing(current) then
            reportMissing(inst, current)
        end
    end

    apply()
    inst:GetPropertyChangedSignal("Text"):Connect(apply)
end

local function watch(root)
    if not root then return end
    pcall(function()
        for _, d in ipairs(root:GetDescendants()) do
            hook(d)
        end
        root.DescendantAdded:Connect(hook)
    end)
end

local function startWatching()
    watch(CoreGui)

    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then watch(pg) end
    end

    -- 很多注入器把 UI 放在 gethui() 里
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then watch(hui) end
    end
end

------------------------------------------------------------------
-- 彩虹签名
------------------------------------------------------------------
local function createRGBSignature()
    if not LocalPlayer then return end

    local parent
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then parent = hui end
    end
    parent = parent or LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "EternalSignature"
    gui.ResetOnSpawn = false
    gui.Parent = parent

    local text = Instance.new("TextLabel")
    text.Parent = gui
    text.Size = UDim2.new(0, 300, 0, 50)
    text.Position = UDim2.new(0.5, -150, 0, 20)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Text = "永恒\n汉化作者: 永恒"

    local hue = 0
    local conn
    conn = RunService.RenderStepped:Connect(function()
        -- 界面被销毁后断开连接，避免泄漏
        if not gui.Parent then
            conn:Disconnect()
            return
        end
        hue = (hue + 0.005) % 1
        text.TextColor3 = Color3.fromHSV(hue, 1, 1)
    end)
end

------------------------------------------------------------------
-- 启动
------------------------------------------------------------------
local function startTranslation()
    createMissingUI()
    startWatching()
    createRGBSignature()
end

local function loadScript()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://hoshihub.site/loader.lua"))()
    end)
    if not success then
        warn("加载失败:", err)
    end
end

if RunScriptFirst then
    loadScript()
    task.wait(2)
    startTranslation()
else
    startTranslation()
    loadScript()
end
