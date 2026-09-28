local RunScriptFirst = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------
-- 汉化数据
-- Common  : 所有游戏通用的词（配置、设置、信息等）
-- Games   : 每个游戏一份独立汉化，自动按下面的条件匹配当前游戏
--   name         显示名（也可用于 ForceGame 手动指定）
--   ids          填 game.PlaceId 或 game.GameId，精确匹配（最推荐）
--   names        游戏名包含这些关键字就匹配（不区分大小写）
--   translations 该游戏专属的汉化表
--   patterns     该游戏专属的动态文本规则（带数字的文本）
-- 新增游戏：复制一份 { ... } 块，改 name / ids / names，再填汉化即可。
------------------------------------------------------------------
local ForceGame = nil   -- 想手动指定汉化时填游戏 name，例如 "Steal An Egg"；nil = 自动匹配

local function cnTime(s)
    s = s:gsub("(%d+)h", "%1时")
    s = s:gsub("(%d+)m", "%1分")
    s = s:gsub("(%d+)s", "%1秒")
    return s
end

local Common = {
    ["Settings"] = "设置",
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

local Games = {
    {
        name = "Lemon Tycoon",          -- 名称是猜的，请核对；在漏翻窗口标题里能看到实际游戏名
        ids = {},                       -- 建议填 PlaceId
        names = { "Lemon" },
        translations = {
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
        },
        patterns = {},
    },

    {
        name = "Steal An Egg",
        ids = { 107778070777162 },      -- PlaceId
        names = { "Steal An Egg" },
        translations = {
        ["No matching features"] = "没有匹配的功能",
        ["FREE"] = "免费",
        ["Auto Steal"] = "自动偷蛋",
        ["Targeting"] = "目标选择",
        ["Behavior"] = "行为",
        ["Status"] = "状态",
        ["Idle"] = "空闲",
        ["Areas"] = "区域",
        ["All areas"] = "所有区域",
        ["Forest"] = "森林",
        ["Lake"] = "湖泊",
        ["Desert"] = "沙漠",
        ["Jungle"] = "丛林",
        ["Snow"] = "雪地",
        ["Volcano"] = "火山",
        ["Abyss Ocean"] = "深渊海洋",
        ["Prehistoric"] = "史前",
        ["Cosmic"] = "宇宙",
        ["Cherry Blossom"] = "樱花",
        ["Titan Temple"] = "泰坦神殿",
        ["Rarities"] = "稀有度",
        ["All rarities"] = "所有稀有度",
        ["Common"] = "普通",
        ["Uncommon"] = "优良",
        ["Rare"] = "稀有",
        ["Epic"] = "史诗",
        ["Legendary"] = "传说",
        ["Mythic"] = "神话",
        ["Secret"] = "隐藏",
        ["Eternal"] = "永恒",
        ["Divine"] = "神圣",
        ["Pick Target By"] = "选择目标方式",
        ["Farthest"] = "最远",
        ["Highest Rarity"] = "最高稀有度",
        ["Highest Income"] = "最高收入",
        ["Nearest"] = "最近",
        ["Heaviest"] = "最重",
        ["Minimum Weight (Kg, 0 = any)"] = "最小重量（Kg，0=不限）",
        ["Maximum Weight (Kg, 0 = no cap)"] = "最大重量（Kg，0=无上限）",
        ["Minimum Income /s (0 = any)"] = "最低收入/秒（0=不限）",
        ["Auto Steal Speed (0 = default)"] = "自动偷蛋速度（0=默认）",
        ["Steal Mode"] = "偷蛋模式",
        ["TP"] = "传送",
        ["Tween"] = "补间移动",
        ["Deliver Egg To"] = "蛋送往",
        ["Safe Zone"] = "安全区",
        ["Forest Zone"] = "森林区",
        ["Stop When Egg Bag Is Full"] = "蛋包满时停止",
        ["Guard Godmode"] = "守卫无敌模式",
        ["Drop Egg When Guard Catches Up"] = "守卫追上时丢蛋",
        ["Bat Aura"] = "球棒光环",
        ["Nearest Guard"] = "最近的守卫",
        ["Guard Shield"] = "守卫护盾",
        ["Travel Speed"] = "移动速度",
        ["Steal Log"] = "偷蛋记录",
        ["No steals yet."] = "暂无偷蛋记录。",
        ["Eternal Spawns · Next 24 Hours"] = "永恒刷新 · 未来24小时",
        ["No Eternal pets in the next 24 hours."] = "未来24小时内没有永恒宠物。",
        ["Server Hop"] = "换服",
        ["Wait Before Hopping (seconds)"] = "换服前等待（秒）",
        ["Max Hops Per Reset"] = "每次重置最大换服次数",
        ["Auto Hop"] = "自动换服",
        ["Inventory ESP"] = "背包透视",
        ["Puts income/s and rarity on a small card above each item's picture, inside the game's own bag and hotbar — separate from the item title, so the numbers stay readable."] = "在游戏自带的背包和快捷栏中，每个物品图片上方显示一张小卡片，标明收入/秒和稀有度，与物品标题分开，数字更易读。",
        ["Egg Pen ESP"] = "蛋圈透视",
        ["Floating label on every egg growing in your own pen: what hatches from it, rarity, income/s, weight, mutations and time left."] = "在你自己蛋圈里每个生长中的蛋上方显示浮动标签：孵出什么、稀有度、收入/秒、重量、变异和剩余时间。",
        ["Eggs Tagged"] = "已标记的蛋",
        ["Stealable Egg ESP"] = "可偷蛋透视",
        ["Floating label on every field egg you can still take (in its nest or dropped on the ground): what hatches from it, rarity, income/s, weight, its area and distance."] = "在野外每个仍可拿取的蛋（在巢里或掉在地上）上方显示浮动标签：孵出什么、稀有度、收入/秒、重量、所在区域和距离。",
        ["ESP Range (studs)"] = "透视范围（格）",
        ["Auto Egg"] = "自动蛋",
        ["Place"] = "放置",
        ["Hatch"] = "孵化",
        ["Place Rarities"] = "放置稀有度",
        ["Auto Place"] = "自动放置",
        ["Hatch Rarities"] = "孵化稀有度",
        ["Hatch Order"] = "孵化顺序",
        ["Oldest"] = "最旧",
        ["Auto Hatch"] = "自动孵化",
        ["Fuse Machine"] = "融合机",
        ["Fuse These Rarities"] = "融合这些稀有度",
        ["Only Fuse Under (Kg, 0 = any)"] = "仅融合低于（Kg，0=不限）",
        ["Stop When Money Below"] = "金钱低于此值时停止",
        ["Max Fuses Per Run (0 = unlimited)"] = "每次最大融合数（0=无限）",
        ["Auto Fuse (3 of a kind)"] = "自动融合（3个同种）",
        ["Egg Inventory"] = "蛋背包",
        ["In Bag"] = "背包中",
        ["Bag Value"] = "背包价值",
        ["Best Egg"] = "最佳蛋",
        ["Growing"] = "生长中",
        ["Next Ready"] = "下一个就绪",
        ["Pet Pen"] = "宠物圈",
        ["Pets Owned"] = "拥有的宠物",
        ["Equip Best Now"] = "立即装备最佳",
        ["Auto Equip Best"] = "自动装备最佳",
        ["Sell Pets"] = "出售宠物",
        ["Sell These Rarities"] = "出售这些稀有度",
        ["None selected"] = "未选择",
        ["Only Sell Under (Kg, 0 = any)"] = "仅出售低于（Kg，0=不限）",
        ["Keep Heaviest Per Species"] = "每个品种保留最重的",
        ["Never Sell Favorites"] = "从不出售收藏",
        ["Will Sell"] = "将出售",
        ["Auto Sell Pets"] = "自动出售宠物",
        ["Economy"] = "经济",
        ["Money"] = "金钱",
        ["Pen Level"] = "蛋圈等级",
        ["Claim Offline Money Now"] = "立即领取离线金钱",
        ["Claim Only Above"] = "仅在高于此值时领取",
        ["Auto Claim Offline Money"] = "自动领取离线金钱",
        ["Upgrade Pen Until Level"] = "升级蛋圈直到等级",
        ["Auto Upgrade Pen"] = "自动升级蛋圈",
        ["Index"] = "图鉴",
        ["Claim All Index Rewards"] = "领取所有图鉴奖励",
        ["Auto Claim Index"] = "自动领取图鉴",
        ["Events & Rewards"] = "活动与奖励",
        ["Claim Monster Chest"] = "领取怪物宝箱",
        ["Auto Monster Chest"] = "自动怪物宝箱",
        ["Auto Group Perk"] = "自动群组福利",
        ["Auto Limited Egg"] = "自动限定蛋",
        ["Great Bloom"] = "大绽放",
        ["Bloom"] = "绽放",
        ["Crystals"] = "水晶",
        ["Auto Farm Sakura Trees"] = "自动刷樱花树",
        ["Sakura Incubator"] = "樱花孵化器",
        ["Access"] = "权限",
        ["Charge"] = "充能",
        ["Auto Unlock / Insert / Deposit / Mutate"] = "自动解锁 / 放入 / 存入 / 变异",
        ["Rift Event"] = "裂隙活动",
        ["Rift"] = "裂隙",
        ["Recipe"] = "配方",
        ["Pity"] = "保底",
        ["Grind"] = "刷取",
        ["Auto Rift Trade-In"] = "自动裂隙兑换",
        ["Auto Grind Rift Egg"] = "自动刷裂隙蛋",
        ["Use Free Rerolls"] = "使用免费重抽",
        ["Boss Mastery"] = "Boss精通",
        ["Boss Window"] = "Boss窗口",
        ["Mastery"] = "精通",
        ["Auto Claim Milestones + Shop"] = "自动领取里程碑 + 商店",
        ["Auto Fight Boss"] = "自动打Boss",
        ["Also Attack Boss (no dodging yet)"] = "同时攻击Boss（暂无闪避）",
        ["Fight"] = "战斗",
        ["Buy With Boss Tokens"] = "用Boss代币购买",
        ["Nothing (safe default)"] = "无（安全默认）",
        ["CashBooster"] = "现金加成器",
        ["SpeedBoost"] = "速度提升",
        ["TreadmillBooster"] = "跑步机加成器",
        ["MutationConsumable"] = "变异消耗品",
        ["Dr Scramble"] = "斯克兰博士",
        ["Outbreak"] = "爆发",
        ["Samples"] = "样本",
        ["Vault"] = "金库",
        ["Auto Farm Drones"] = "自动刷无人机",
        ["Auto Quest (unlock The Scrambler)"] = "自动任务（解锁扰乱者）",
        ["One-time: collects 2 Lost Parts, talks to the experiment, then claims the vault. Runs only between outbreaks and pauses Auto Steal while it travels."] = "一次性：收集2个遗失部件，与实验体对话，然后领取金库。仅在爆发之间运行，移动期间会暂停自动偷蛋。",
        ["Buy With Samples"] = "用样本购买",
        ["Treadmill"] = "跑步机",
        ["Next Tier"] = "下一阶",
        ["Stay On Treadmill"] = "停留在跑步机上",
        ["Upgrade Treadmill Until Tier"] = "升级跑步机直到阶级",
        ["Auto Upgrade Treadmill"] = "自动升级跑步机",
        ["Trail"] = "轨迹",
        ["Equipped"] = "已装备",
        ["Best Owned"] = "拥有的最佳",
        ["Auto Buy & Equip Trail"] = "自动购买并装备轨迹",
        ["Buy Trail Until Tier"] = "购买轨迹直到阶级",
        ["Progress"] = "进度",
        ["Speed Power"] = "速度能力",
        ["Walk Speed"] = "行走速度",
        ["Treadmill Tiers"] = "跑步机阶级",
        ["Webhook URL 1"] = "Webhook 链接 1",
        ["Ping Discord User ID"] = "提醒的 Discord 用户ID",
        ["Use @everyone Instead"] = "改用 @everyone",
        ["Send Test"] = "发送测试",
        ["Pet Hatched"] = "宠物已孵化",
        ["Webhook To Use"] = "使用的Webhook",
        ["Webhook 1"] = "Webhook 1",
        ["Any"] = "任意",
        ["Min Money/sec"] = "最低金钱/秒",
        ["Username"] = "用户名",
        ["Uptime"] = "运行时间",
        ["Egg Stolen"] = "蛋被偷",
        ["none"] = "无",
        ["Import / Export"] = "导入 / 导出",
        ["Export (Copy JSON)"] = "导出（复制JSON）",
        ["Import (Paste JSON)"] = "导入（粘贴JSON）",
        ["Auto Execute"] = "自动执行",
        ["Auto Rejoin on Disconnect"] = "断线自动重连",
        ["Toggle UI Keybind"] = "切换界面快捷键",
        ["Web Status"] = "网页状态",
        ["Off"] = "关",
        ["Reports this account to the Steal An Egg dashboard as Main. SAEKaitun accounts appear as Kaitun. Paid access required."] = "将此账号作为主号上报到 Steal An Egg 仪表盘。SAEKaitun 账号显示为 Kaitun。需要付费权限。",
        ["Web Connection"] = "网页连接",
        ["Hide Pet Target"] = "隐藏宠物目标",
        ["Both"] = "两者",
        ["Own Pets"] = "自己的宠物",
        ["Other Pets"] = "其他宠物",
        ["Hide Pets"] = "隐藏宠物",
        ["Hide Egg Target"] = "隐藏蛋目标",
        ["Own Eggs"] = "自己的蛋",
        ["Other Eggs"] = "其他蛋",
        ["Hide Eggs"] = "隐藏蛋",
        ["Performance Mode (strips map, needs rejoin to undo)"] = "性能模式（移除地图，需重新加入才能还原）",
        ["Script"] = "脚本",
        ["Copy Discord"] = "复制Discord",
        ["Unload Script"] = "卸载脚本",
        ["Plot Slot"] = "地块槽位",
            ["Rebirth"] = "重生",
            ["ESP"] = "透视",
            ["Eggs"] = "蛋",
            ["Plot"] = "地块",
            ["Event"] = "活动",
            ["Steal"] = "偷蛋",
        ["off"] = "关",
        ["not active"] = "未激活",
        ["closed"] = "已关闭",
        ["None"] = "无",
        },
        patterns = {
            { "^next in (%d+[hms].*)$", function(t) return "下次 " .. cnTime(t) .. "后" end },
            { "^in (%d+[hms].*)$", function(t) return cnTime(t) .. "后" end },
            { "^(%d+) pet%(s%)$", "%1 只宠物" },
            { "^([%d%.,]+) studs/s$", "%1 格/秒" },
            { "^(%d+)/(%d+) parts · talk to the experiment first$", "%1/%2 部件 · 先与实验体对话" },
            { "^Sci%-Fi Treadmill · (.+)$", "科幻跑步机 · %1" },
        },
    },
}

------------------------------------------------------------------
-- 自动选择当前游戏的汉化
------------------------------------------------------------------
local GameName = ""
pcall(function()
    GameName = tostring(game.Name or "")
end)

local function findGame()
    for _, g in ipairs(Games) do
        if ForceGame then
            if g.name == ForceGame then return g end
        else
            for _, id in ipairs(g.ids or {}) do
                if id == game.PlaceId or id == game.GameId then return g end
            end
            local lowerName = GameName:lower()
            for _, n in ipairs(g.names or {}) do
                if lowerName:find(n:lower(), 1, true) then return g end
            end
        end
    end
    return nil
end

local CurrentGame = findGame()

-- 合并：通用 + 当前游戏（同名以游戏专属为准）
local Translations = {}
for k, v in pairs(Common) do Translations[k] = v end
if CurrentGame then
    for k, v in pairs(CurrentGame.translations) do Translations[k] = v end
end
local PatternRules = (CurrentGame and CurrentGame.patterns) or {}

-- 漏翻窗口里显示的游戏标签，方便你确认匹配到了哪个
local TranslationCount = 0
for _ in pairs(Translations) do TranslationCount = TranslationCount + 1 end

local GameLabel
if CurrentGame then
    GameLabel = CurrentGame.name .. " · " .. TranslationCount .. "条"
else
    GameLabel = "未匹配 " .. GameName .. " (" .. tostring(game.PlaceId) .. ")"
end

------------------------------------------------------------------
-- 翻译逻辑
-- 只做"整句精确匹配"，避免短词（Auto / key / Game）误伤其他文本。
-- 另外支持 "标签: 数值" 形式（如 "Cash: 123" -> "现金: 123"）。
------------------------------------------------------------------
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


-- 把 "标签: 数值" 拆成 标签、冒号、数值（支持半角 : 和全角 ：）
local function splitLabel(text)
    local a = text:find(":", 1, true)
    local b = text:find("：", 1, true)
    local pos, len
    if a and (not b or a < b) then
        pos, len = a, 1
    elseif b then
        pos, len = b, #"："
    else
        return nil
    end
    local label = text:sub(1, pos - 1):gsub("%s+$", "")
    return label, text:sub(pos, pos + len - 1), text:sub(pos + len)
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
    local label, sep, rest = splitLabel(text)
    if label and label ~= "" then
        local t = Translations[trim(label)]
        if t then return t .. sep .. rest end
    end

    -- 4. 动态文本规则
    for _, rule in ipairs(PatternRules) do
        local r, n = text:gsub(rule[1], rule[2])
        if n > 0 then return r end
    end

    return text
end

------------------------------------------------------------------
-- 漏翻检测：UI 上出现了、但翻译表里没有的英文，会集中显示在一个可复制的小窗口里
------------------------------------------------------------------
local DebugMissing = true          -- 不需要时改成 false
local DetectOnlyHub = true         -- true = 只检测 loadstring 加载出来的脚本界面，不检测游戏自带 UI
local reported = {}                -- 已报告过的文本（数字替换成 # 后去重）
local MissingList = {}             -- 所有漏翻文本，方便统一复制

local function isMissing(text)
    local trimmed = trim(text)
    if trimmed == "" then return false end
    if not trimmed:find("%a") then return false end            -- 纯数字/符号
    if trimmed:find("[\228-\233]") then return false end       -- 已含中文
    if Translations[trimmed] then return false end             -- 表里有（如 Discord）

    -- 去掉富文本标签和数字后，只剩 FPS / Kg 等单位则不算漏翻
    local rest = trimmed:gsub("<[^>]+>", ""):gsub("[%d%.,/%s]", "")
    if rest == "FPS" or rest == "Kg" or rest == "" then return false end

    local label = splitLabel(trimmed)
    if label and label ~= "" and Translations[trim(label)] then
        return false
    end
    return true
end

local MISSING_GUI_NAME = "EternalMissing"

-- 记录脚本加载前已经存在的界面，之后新出现的顶层界面才算"脚本界面"
local preexisting = setmetatable({}, { __mode = "k" })

local function getRoots()
    local roots = { CoreGui }
    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then table.insert(roots, pg) end
    end
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(roots, hui) end
    end
    return roots
end

local function takeSnapshot()
    for _, root in ipairs(getRoots()) do
        pcall(function()
            for _, child in ipairs(root:GetChildren()) do
                preexisting[child] = true
            end
        end)
    end
end

local function isHubInstance(inst)
    local rootSet = {}
    for _, r in ipairs(getRoots()) do rootSet[r] = true end

    local cur = inst
    while cur and cur.Parent do
        if rootSet[cur.Parent] then
            if preexisting[cur] then return false end
            if cur.Name == MISSING_GUI_NAME or cur.Name == "EternalSignature" then return false end
            return true
        end
        cur = cur.Parent
    end
    return false
end

local missingBox, missingTitle

local function refreshMissingUI()
    if missingBox then
        missingBox.Text = table.concat(MissingList, "\n")
    end
    if missingTitle then
        missingTitle.Text = "漏翻(" .. #MissingList .. ") · " .. GameLabel
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
    local candidates = {
        setclipboard,
        toclipboard,
        set_clipboard,
        (type(Clipboard) == "table" and Clipboard.set) or nil,
        (type(syn) == "table" and syn.write_clipboard) or nil,
    }
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            local ok = pcall(fn, out)
            if ok then return true end
        end
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
    missingTitle.TextSize = 12
    missingTitle.TextTruncate = Enum.TextTruncate.AtEnd
    missingTitle.TextColor3 = Color3.new(1, 1, 1)
    missingTitle.Text = "漏翻(0) · " .. GameLabel
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
        if #MissingList == 0 then
            copyBtn.Text = "列表为空"
        elseif copyMissing() then
            copyBtn.Text = "已复制 ✓"
        else
            -- 执行器不支持剪贴板：自动全选文本，按 Ctrl+C 即可
            pcall(function()
                missingBox:CaptureFocus()
                missingBox.SelectionStart = 1
                missingBox.CursorPosition = #missingBox.Text + 1
            end)
            copyBtn.Text = "已全选,按Ctrl+C"
        end
        task.delay(1.5, function()
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
        elseif DebugMissing and isMissing(current)
            and (not DetectOnlyHub or isHubInstance(inst)) then
            local snapshotText = current
            task.delay(0.8, function()
                local ok, still = pcall(function()
                    return inst.Parent ~= nil and inst.Text == snapshotText
                end)
                if ok and still and isMissing(snapshotText) then
                    reportMissing(inst, snapshotText)
                end
            end)
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
    -- 先启动汉化监听（最重要），其他界面放到独立线程里，出错也不影响
    local ok, err = pcall(startWatching)
    if not ok then warn("汉化监听启动失败:", err) end

    task.spawn(function()
        local ok2, err2 = pcall(createMissingUI)
        if not ok2 then warn("漏翻窗口创建失败:", err2) end
    end)

    task.spawn(function()
        local ok3, err3 = pcall(createRGBSignature)
        if not ok3 then warn("签名创建失败:", err3) end
    end)
end

local function loadScript()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://hoshihub.site/loader.lua"))()
    end)
    if not success then
        warn("加载失败:", err)
    end
end

takeSnapshot() -- 必须在加载脚本之前

if RunScriptFirst then
    loadScript()
    task.wait(2)
    startTranslation()
else
    startTranslation()
    loadScript()
end
