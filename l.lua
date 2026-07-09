local RunScriptFirst = false

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
    ["Set as Auto-Load"] = "设置为自动加载",
    ["Clear Auto-Load"] = "清除自动加载",
    ["Delete Selected"] = "删除选择项",
    ["Load Selected"] = "加载选择",
    ["Load Selectet"] = "加载选择",
    
}

local function processTextComponent(gui, newText)
    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
        pcall(function()
            gui.RichText = true
            if gui:FindFirstChildOfClass("UITextSizeConstraint") then
                gui.UITextSizeConstraint.MaxTextSize = gui.TextSize
            end
        end)
    end
    return newText
end

local Printed = {}

local function normalizeText(text)
    -- 去除数字，避免 Cash:100 / Cash:200 这种重复提示
    text = text:gsub("%d+", "NUM")
    -- 合并多余空格
    text = text:gsub("%s+", " ")
    return text
end

local function translateText(text)
    if not text or type(text) ~= "string" then
        return text
    end
    -- 空文本不处理
    if text == "" or #text < 2 then
        return text
    end
    -- 完全匹配
    if Translations[text] then
        return Translations[text]
    end
    -- 包含匹配
    for en, cn in pairs(Translations) do
        if text:find(en, 1, true) then
            -- 转义特殊字符，避免 gsub 把它当正
            local escaped = en:gsub("(%W)", "%%%1")
            return text:gsub(escaped, cn)
        end
    end
    -- 记录没有翻译的文本
    local key = normalizeText(text)
    if not Printed[key] then
        Printed[key] = true
        warn("未翻译文本: [" .. text .. "]")
    end
    return text
end

local function translateAllElements()
    local function translateGui(gui)
        for _, element in ipairs(gui:GetDescendants()) do
            if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
                local currentText = element.Text
                if currentText and currentText ~= "" then
                    local translatedText = translateText(currentText)
                    if translatedText ~= currentText then
                        element.Text = processTextComponent(element, translatedText)
                    end
                end
            end
        end
    end

    pcall(translateGui, game:GetService("CoreGui"))

    local player = game:GetService("Players").LocalPlayer
    if player and player:FindFirstChild("PlayerGui") then
        pcall(translateGui, player.PlayerGui)
    end
end

local function setupListener()
    local function connectToGui(gui)
        gui.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                local currentText = descendant.Text
                if currentText and currentText ~= "" then
                    local translatedText = translateText(currentText)
                    if translatedText ~= currentText then
                        descendant.Text = processTextComponent(descendant, translatedText)
                    end
                end

                descendant:GetPropertyChangedSignal("Text"):Connect(function()
                    local newText = descendant.Text
                    if newText and newText ~= "" then
                        local translatedText = translateText(newText)
                        if translatedText ~= newText then
                            descendant.Text = processTextComponent(descendant, translatedText)
                        end
                    end
                end)
            end
        end)
    end

    pcall(connectToGui, game:GetService("CoreGui"))

    local player = game:GetService("Players").LocalPlayer
    if player and player:FindFirstChild("PlayerGui") then
        pcall(connectToGui, player.PlayerGui)
    end
end

local function createRGBSignature()
    local player = game:GetService("Players").LocalPlayer
    if not player then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DavidSignature"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local text = Instance.new("TextLabel")
    text.Parent = gui

    text.Size = UDim2.new(0,300,0,50)
    text.Position = UDim2.new(0.5,-150,0,20)

    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold

    text.Text = "永恒\n汉化作者: 永恒"

    local hue = 0

    game:GetService("RunService").RenderStepped:Connect(function()

        hue += 0.005

        if hue >= 1 then
            hue = 0
        end

        text.TextColor3 = Color3.fromHSV(
            hue,
            1,
            1
        )

    end)
end

local function startTranslation()
    translateAllElements()
    setupListener()
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
