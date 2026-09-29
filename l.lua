--[[ ==============================================================
  永恒汉化脚本 —— 文件结构说明（方便自己以后修改）

  这个脚本做两件事：
    1. 监听 hub 的界面，把英文文字换成中文
    2. 加载 hub 本体（loadscript 那一段）

  文件从上到下分这几块：
    1. 启动开关、服务          最上面
    2. 汉化数据                通用汉化表 Common + 每个游戏一块的 Games
    3. 选择当前游戏            findGame：按 PlaceId 或游戏名匹配，合并出最终汉化表
    4. 翻译逻辑                translateText：整句匹配 / 标签冒号数值 / 动态规则
    5. 界面识别                getRoots、takeSnapshot、containsGameText
    6. 设置与开关              ScriptVersion、设置保存、setTranslationEnabled
    7. 挂钩汉化                hook（每个文字控件）、confirmHub、considerTop、startWatching
    8. 签名胶囊                createRGBSignature（小胶囊，位置可配置，点击开关汉化）
    9. 启动                    startTranslation、loadScript、最后的顺序判断

  常见修改：
    - 补一条汉化    在对应游戏的 translations 里加 ["英文"] = "中文",
    - 新增游戏      复制 Games 里一整个 { } 块，改 name / ids / names，再填汉化
    - 改署名        找 createRGBSignature 里的 refreshText
    - 改开关快捷键  改 ToggleKey
    - 关掉更新提示  UpdateURL 保持 nil

  发布注意：
    - 标着 DEV_BEGIN 和 DEV_END 两行标记之间的是开发专用代码
    - 发给用户的文件用 build_user.py 生成，会把标记之间的内容整块删掉
    - 不要手动改用户版，永远只改这个文件
    - 注释里不要写开发专用的函数名或变量名，否则构建脚本会认为有残留而拒绝生成
================================================================== ]]

-- 启动顺序开关（见文件末尾的启动部分）：
-- false = 先启动汉化监听，再加载 hub，hub 界面一出现就能翻译（推荐）
-- true  = 先加载 hub，等 2 秒后再启动汉化
local RunScriptFirst = false

--@DEV_BEGIN
-- 开发版 = true（带漏翻检测窗口）。用户版由 build_user.py 生成，里面不包含任何开发代码。
local DevMode = true
-- 开发版目标帧率上限（需要执行器支持 setfpscap）；填 nil 表示不修改
local FpsCap = 240
--@DEV_END

-- 常用的 Roblox 内置服务
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
-- 当前玩家，后面用它找 PlayerGui（玩家界面容器）
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

-- 把英文时间缩写换成中文：1h -> 1时，2m -> 2分，3s -> 3秒
-- 给下面各游戏的动态文本规则（patterns）使用
local function cnTime(s)
    s = s:gsub("(%d+)h", "%1时")
    s = s:gsub("(%d+)m", "%1分")
    s = s:gsub("(%d+)s", "%1秒")
    return s
end

-- 通用汉化表：所有游戏都会加载
-- 格式：["英文原文"] = "中文译文"，英文必须和界面上的文字完全一致（区分大小写、空格）
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

-- 游戏列表：每个游戏一个 { } 块
-- 运行时只加载「通用 + 当前游戏」这两份，游戏之间互不干扰
local Games = {
    {
        -- 游戏块 1
        -- name  显示名（也用于 ForceGame 手动指定）
        -- ids   填 PlaceId 或 GameId，精确匹配（最推荐，填了就不靠游戏名）
        -- names 游戏名包含这些关键字就匹配（不区分大小写）
        name = "Lemon Tycoon",          -- 名称是猜的，请核对；在漏翻窗口标题里能看到实际游戏名
        ids = {},                       -- 建议填 PlaceId
        names = { "Lemon" },
        -- 该游戏专属汉化表，同名词条会覆盖上面的通用表
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
        -- 动态文本规则（带数字的文本），这个游戏暂时没有
        patterns = {},
    },

    {
        -- 游戏块 2：Steal An Egg（ids 已填 PlaceId）
        name = "Steal An Egg",
        ids = { 107778070777162 },      -- PlaceId
        names = { "Steal An Egg" },
        -- 该游戏专属汉化表
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
        -- 动态文本规则：每条 { 匹配模式, 替换内容 }
        -- 模式是 Lua 模式（不是正则）：%d 数字、(.+) 捕获、%1 引用捕获、特殊字符前加 % 转义
        -- 替换内容可以是字符串，也可以是函数（参数是捕获到的内容，返回替换后的文字）
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
-- 当前游戏名（game.Name 不会卡住），用于按名字匹配和界面提示
local GameName = ""
pcall(function()
    GameName = tostring(game.Name or "")
end)

-- 找当前游戏对应的配置，没匹配到返回 nil
-- ForceGame 优先；否则先按 ids 匹配，再按 names 关键字匹配
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

-- 当前游戏配置（nil = 没匹配到，此时只加载通用汉化）
local CurrentGame = findGame()

-- 合并：通用 + 当前游戏（同名以游戏专属为准）
-- 合并出最终使用的汉化表：先放通用，再放当前游戏的（同名以游戏专属为准）
local Translations = {}
for k, v in pairs(Common) do Translations[k] = v end
if CurrentGame then
    for k, v in pairs(CurrentGame.translations) do Translations[k] = v end
end
-- 动态文本规则（当前游戏的 patterns，没有就是空表）
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
-- 去掉首尾空白。外层多加一层括号，是为了只返回第一个值（gsub 会返回两个值）
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


-- 把 "标签: 数值" 拆成 标签、冒号、数值（支持半角 : 和全角 ：）
local function splitLabel(text)
    -- 分别找半角冒号和全角冒号的位置（第 4 个参数 true = 按普通文字查找，不当模式）
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

-- 翻译核心函数：传入界面上的文字，返回翻译后的文字，没有匹配就原样返回
-- 匹配顺序：整句 -> 去空白 -> 「标签: 数值」 -> 动态规则
-- 刻意不做子串替换，避免 Auto、key 这类短词误伤别的文字
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
local HubOnly = true               -- true = 只汉化脚本自己的界面，不碰游戏和执行器的界面（更快）
--@DEV_BEGIN
local DebugMissing = DevMode      -- 漏翻检测开关
-- 不需要翻译的文本（按键名、版本号、链接等），不会进漏翻窗口
local IgnoreTexts = { "RightControl", "RightShift", "LeftControl", "LeftShift", "Delta" }
local IgnorePatterns = { "^v[%d%.]+$", "discord%.gg/", "^https?://" }
local IgnoreSet = {}
for _, t in ipairs(IgnoreTexts) do IgnoreSet[t] = true end

local reported = {}                -- 已报告过的文本（数字替换成 # 后去重）
local MissingList = {}             -- 所有漏翻文本，方便统一复制

-- 判断一段文字是不是「漏翻」：含英文字母、不含中文、汉化表里没有、也不在忽略列表里
-- 返回 true 表示需要报告
local function isMissing(text)
    local trimmed = trim(text)
    if trimmed == "" then return false end
    if not trimmed:find("%a") then return false end            -- 纯数字/符号
    if trimmed:find("[\228-\233]") then return false end       -- 已含中文
    if Translations[trimmed] then return false end             -- 表里有（如 Discord）
    if IgnoreSet[trimmed] then return false end                -- 忽略列表
    for _, p in ipairs(IgnorePatterns) do
        if trimmed:find(p) then return false end
    end

    -- 去掉富文本标签和数字后，只剩 FPS / Kg 等单位则不算漏翻
    local rest = trimmed:gsub("<[^>]+>", ""):gsub("[%d%.,/%s]", "")
    if rest == "FPS" or rest == "Kg" or rest == "" then return false end

    local label = splitLabel(trimmed)
    if label and label ~= "" and Translations[trim(label)] then
        return false
    end
    return true
end
--@DEV_END

-- 开发面板的界面名称：汉化监听会跳过这个名字的界面，避免自己检测自己
local MISSING_GUI_NAME = "EternalMissing"

-- 记录脚本加载前已经存在的界面，之后新出现的顶层界面才算"脚本界面"
local preexisting = {}   -- 强引用：只有几个顶层界面，不会造成泄漏

-- 所有可能放脚本界面的容器：CoreGui、PlayerGui，以及 gethui()（很多执行器把界面放在这里）
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

-- 记录脚本启动时已有的顶层界面（执行器、游戏自带的界面）
-- 之后新出现的界面才有可能是脚本界面。必须在加载 hub 之前调用
local function takeSnapshot()
    for _, root in ipairs(getRoots()) do
        pcall(function()
            for _, child in ipairs(root:GetChildren()) do
                preexisting[child] = true
            end
        end)
    end
end

-- 当前游戏汉化表里的所有文本（英文原文 + 中文译文），用来识别"哪个界面是脚本界面"
local GameTextSet = {}
if CurrentGame then
    for k, v in pairs(CurrentGame.translations) do
        GameTextSet[k] = true
        GameTextSet[v] = true
    end
end
local HasGameTexts = next(GameTextSet) ~= nil

local hubTop = {}       -- 已确认是脚本界面的顶层 GUI

-- 检查一个顶层界面里有没有出现当前游戏汉化表里的文字（英文原文或中文译文）
-- 有 = 说明它是脚本界面。遍历所有后代控件，所以不要太频繁调用
local function containsGameText(top)
    local list = top:GetDescendants()
    for i = 1, #list do
        local d = list[i]
        local c = d.ClassName   -- 直接比类名，比连续调用三次 IsA 快
        if c == "TextLabel" or c == "TextButton" or c == "TextBox" then
            if GameTextSet[d.Text] then return true end
        end
        -- 界面很大时每检查 400 个控件让出一帧，避免卡顿（240 帧下一帧只有约 4 毫秒）
        if i % 400 == 0 then task.wait() end
    end
    return false
end

--@DEV_BEGIN
local missingBox, missingTitle

-- 刷新开发面板：更新文本框内容和标题里的数量
local missingFps = 0            -- 当前帧率（面板自己每 0.5 秒统计一次）
local MAX_MISSING = 500        -- 最多记录多少条，防止列表无限变长拖慢面板

-- 只刷新标题：漏翻数量、当前游戏、帧率
local function refreshTitle()
    if missingTitle then
        missingTitle.Text = "漏翻(" .. #MissingList .. ") · " .. GameLabel .. " · " .. missingFps .. "fps"
    end
end

local function refreshMissingUI()
    if missingBox then
        missingBox.Text = table.concat(MissingList, "\n")
    end
    refreshTitle()
end

-- 合并刷新：短时间内多条漏翻只刷新一次（每次刷新都要重排整个文本框，很费性能）
local refreshQueued = false
local function queueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    task.delay(0.25, function()
        refreshQueued = false
        refreshMissingUI()
    end)
end

-- 记录一条漏翻文本：数字换成 # 后去重，同一句只记一次
local function reportMissing(inst, text)
    local trimmed = trim(text)
    local key = trimmed:gsub("%d+", "#")
    if reported[key] then return end
    if #MissingList >= MAX_MISSING then return end
    reported[key] = true
    table.insert(MissingList, (trimmed:gsub("\n", " ")))
    queueRefresh()
end

-- 生成要复制的内容：asCode 为 false 是纯英文每行一条；true 是 ["英文"] = "", 代码格式
local function buildOutput(asCode)
    if not asCode then
        return table.concat(MissingList, "\n")
    end
    local lines = {}
    for _, t in ipairs(MissingList) do
        local esc = t:gsub("\\", "\\\\"):gsub('"', '\\"')
        table.insert(lines, '["' .. esc .. '"] = "",')
    end
    return table.concat(lines, "\n")
end

-- 复制到剪贴板：依次尝试各执行器常见的剪贴板函数，成功返回 true，全都不支持返回 false
local function copyText(out)
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

-- 复制漏翻列表（asCode 决定格式，见 buildOutput）
local function copyMissing(asCode)
    return copyText(buildOutput(asCode))
end

-- 游戏信息文字：显示在面板顶部。PlaceId 是当前地图，GameId 是整个游戏（Universe）
-- 新增游戏汉化时，把 PlaceId 填进该游戏块的 ids，以后就按 ID 精确匹配
local function gameInfoText()
    return string.format(
        "PlaceId %s · GameId %s\n%s · %s",
        tostring(game.PlaceId),
        tostring(game.GameId),
        GameName,
        CurrentGame and ("已匹配 " .. CurrentGame.name) or "未匹配汉化"
    )
end

-- 生成「新增游戏」的代码模板：已经填好 name / ids / names，直接粘进 Games 表里再补词条就行
local function buildGameTemplate()
    local safe = GameName:gsub("\\", "\\\\"):gsub('"', '\\"')
    return table.concat({
        "    {",
        '        name = "' .. safe .. '",',
        "        ids = { " .. tostring(game.PlaceId) .. " },",
        '        names = { "' .. safe .. '" },',
        "        translations = {",
        "        },",
        "        patterns = {},",
        "    },",
    }, "\n")
end

-- 漏翻窗口：所有漏翻英文集中显示，可拖动，可一键复制
local function createMissingUI()
    -- 开发开关关闭时不创建面板
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

    -- 主窗口（可拖动），默认在屏幕右侧
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 260)
    frame.Position = UDim2.new(1, -330, 0.5, -130)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    -- 标题栏：显示漏翻数量和当前游戏，方便确认汉化表是否匹配对
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

    -- 内容区：点「收起」时整块隐藏
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -26)
    body.Position = UDim2.new(0, 0, 0, 26)
    body.BackgroundTransparency = 1
    body.Parent = frame

    -- 创建底部按钮的小工具函数：xScale/wScale 决定横向位置和宽度比例
    local function makeButton(text, xScale, xOffset, wScale)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(wScale, -6, 0, 26)
        b.Position = UDim2.new(xScale, xOffset, 1, -30)
        b.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Text = text
        b.Parent = body
        return b
    end

    -- 游戏信息：PlaceId、GameId、游戏名、是否匹配到汉化
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -8, 0, 32)
    info.Position = UDim2.new(0, 4, 0, 4)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Code
    info.TextSize = 11
    info.TextColor3 = Color3.fromRGB(170, 200, 255)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.TextWrapped = true
    info.Text = gameInfoText()
    info.Parent = body

    -- 可滚动区域：里面放文本框，内容变长时自动撑开
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -76)
    scroll.Position = UDim2.new(0, 4, 0, 40)
    scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = body

    -- 显示漏翻列表的文本框：用 TextBox 是为了不支持剪贴板时可以手动选中复制
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

    -- 四个按钮平分底部宽度：复制全部 / 复制代码 / 清空 / 收起
    local copyBtn = makeButton("复制全部", 0, 4, 0.2)
    local codeBtn = makeButton("复制代码", 0.2, 4, 0.2)
    local idBtn = makeButton("复制ID", 0.4, 4, 0.2)
    local clearBtn = makeButton("清空", 0.6, 4, 0.2)
    local hideBtn = makeButton("收起", 0.8, 4, 0.2)

    -- 给复制按钮绑定点击：getText 返回要复制的内容
    -- 成功显示已复制；执行器不支持剪贴板时，把内容放进文本框并自动全选，按 Ctrl+C 即可
    local function bindCopy(btn, label, getText)
        btn.MouseButton1Click:Connect(function()
            local out = getText()
            if out == "" then
                btn.Text = "列表为空"
            elseif copyText(out) then
                btn.Text = "已复制 ✓"
            else
                missingBox.Text = out
                pcall(function()
                    missingBox:CaptureFocus()
                    missingBox.SelectionStart = 1
                    missingBox.CursorPosition = #missingBox.Text + 1
                end)
                btn.Text = "已全选,按Ctrl+C"
            end
            task.delay(1.5, function()
                btn.Text = label
            end)
        end)
    end
    bindCopy(copyBtn, "复制全部", function() return buildOutput(false) end)
    bindCopy(codeBtn, "复制代码", function() return buildOutput(true) end)
    bindCopy(idBtn, "复制ID", buildGameTemplate)

    -- 清空：同时清掉去重记录，之后同样的文字还会再报
    clearBtn.MouseButton1Click:Connect(function()
        table.clear(MissingList)
        table.clear(reported)
        refreshMissingUI()
    end)

    -- 收起 / 展开：只留标题栏或恢复完整窗口
    hideBtn.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        frame.Size = body.Visible and UDim2.new(0, 320, 0, 260) or UDim2.new(0, 320, 0, 26)
        hideBtn.Text = body.Visible and "收起" or "展开"
    end)

    refreshMissingUI()

    -- 帧率显示：Heartbeat 每帧只做一次加法，每 0.5 秒才更新一次标题，几乎不占性能
    local frames = 0
    local fpsConn = RunService.Heartbeat:Connect(function()
        frames = frames + 1
    end)
    task.spawn(function()
        local last = os.clock()
        while gui.Parent do
            task.wait(0.5)
            local now = os.clock()
            missingFps = math.floor(frames / (now - last) + 0.5)
            frames = 0
            last = now
            refreshTitle()
        end
        fpsConn:Disconnect()
    end)
end

--@DEV_END

------------------------------------------------------------------
-- 版本、设置保存、汉化开关
------------------------------------------------------------------
-- 脚本版本号，改版本时改这里
-- 检查更新功能靠这一行的格式识别线上版本，所以这行格式不要改
local ScriptVersion = "1.1.0"
local UpdateURL = nil                   -- 想要更新提示就填脚本的 raw 链接，例如 "https://raw.githubusercontent.com/你的用户名/仓库名/main/l.lua"
local ToggleKey = Enum.KeyCode.RightShift  -- 键盘快捷键：开/关汉化（手机点签名即可）
-- 签名的位置，可选：TopLeft 左上 / TopCenter 上中 / TopRight 右上 / BottomLeft 左下 / BottomCenter 下中 / BottomRight 右下
local SignaturePosition = "TopRight"
-- 设置文件名（存在执行器的 workspace 目录），用来记住汉化开关
local SettingsFile = "EternalHanhua.json"

-- 用于把设置转成 JSON 文本，或从 JSON 文本读回来
local HttpService = game:GetService("HttpService")
-- 当前设置，目前只有一项：enabled（汉化开关）
local Settings = { enabled = true }

-- 读取设置。执行器不支持文件函数、文件不存在或内容损坏时保持默认值，用 pcall 保护，出错不影响脚本
local function loadSettings()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    pcall(function()
        if isfile(SettingsFile) then
            local data = HttpService:JSONDecode(readfile(SettingsFile))
            if type(data) == "table" and data.enabled ~= nil then
                Settings.enabled = (data.enabled == true)
            end
        end
    end)
end

-- 保存设置到文件（同样用 pcall 保护）
local function saveSettings()
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(SettingsFile, HttpService:JSONEncode(Settings))
    end)
end

-- 启动时先读一次设置
loadSettings()
-- 当前汉化开关状态：true = 开启
local translationEnabled = Settings.enabled

local hooked = setmetatable({}, { __mode = "k" })     -- inst -> apply 函数
local originals = setmetatable({}, { __mode = "k" })  -- inst -> 翻译前的英文原文

-- 判断是不是带文字的控件（标签、按钮、输入框）
local function isTextElement(inst)
    local c = inst.ClassName
    return c == "TextLabel" or c == "TextButton" or c == "TextBox"
end

-- 给一个文字控件挂上汉化：先翻译一次，之后它的文字一变化就再翻译
-- 整个脚本的汉化都靠这个函数
local function hook(inst)
    -- 已经挂过、或者不是文字控件，就跳过
    if hooked[inst] or not isTextElement(inst) then return end
    -- 跳过开发面板自己的控件
    if inst:FindFirstAncestor(MISSING_GUI_NAME) then return end
    -- apply：读取当前文字 -> 翻译 -> 有变化就写回。控件的 Text 每次变化都会执行一次
    local function apply()
        if not translationEnabled then return end
        -- 用户正在输入时不改输入框内容，避免把用户输入的字翻译掉
        if inst:IsA("TextBox") and inst:IsFocused() then return end
        local current = inst.Text
        -- 翻译，没有匹配时返回原文
        local new = translateText(current)
        if new ~= current then
            originals[inst] = current -- 记住英文原文，关闭汉化时还原
            inst.Text = new -- 新文本已是中文，不会再次命中，不会死循环
--@DEV_BEGIN
        -- 没翻译成功：交给开发面板检测。输入框跳过；延迟 0.8 秒再确认，避免界面刚创建时误报
        elseif DebugMissing and not inst:IsA("TextBox") and isMissing(current) then
            local snapshotText = current
            task.delay(0.8, function()
                local ok, still = pcall(function()
                    return inst.Parent ~= nil and inst.Text == snapshotText
                end)
                if ok and still and isMissing(snapshotText) then
                    reportMissing(inst, snapshotText)
                end
            end)
--@DEV_END
        end
    end

    -- 登记这个控件的 apply，开关汉化时可以批量重新执行
    hooked[inst] = apply
    -- 立刻翻译一次
    apply()
    -- 以后文字再变化（计时器刷新、hub 重新写入等）就再翻译一次
    inst:GetPropertyChangedSignal("Text"):Connect(apply)
end

-- 开/关汉化：关闭时把所有已翻译的文字还原成英文，开启时重新翻译
local function setTranslationEnabled(on)
    translationEnabled = on and true or false
    Settings.enabled = translationEnabled
    if translationEnabled then
        -- 开启：对所有已挂钩的控件重新执行 apply
        for _, fn in pairs(hooked) do pcall(fn) end
    else
        -- 关闭：把翻译过的控件恢复成英文原文
        for inst, orig in pairs(originals) do
            pcall(function()
                if inst.Parent then inst.Text = orig end
            end)
        end
    end
    saveSettings()
end

-- HubOnly = false 时的旧方式：监听整个 root（所有界面）
local function watch(root)
    if not root then return end
    pcall(function()
        for _, d in ipairs(root:GetDescendants()) do
            hook(d)
        end
        root.DescendantAdded:Connect(hook)
    end)
end

-- 是不是脚本自己的界面（签名或开发面板），这些不参与汉化
local function isOwnGui(top)
    return top.Name == MISSING_GUI_NAME or top.Name == "EternalSignature"
end

-- 确认 top 是脚本界面：给里面所有文字控件挂上汉化，并监听之后新增的控件
local function confirmHub(top)
    if hubTop[top] then return end
    hubTop[top] = true

    -- 先监听之后新增的控件（新增的立刻挂钩），再分批处理已有控件
    pcall(function()
        top.DescendantAdded:Connect(hook)
    end)

    -- 已有控件每处理 150 个让出一帧，界面再大也不会造成明显卡顿
    task.spawn(function()
        local ok, list = pcall(function() return top:GetDescendants() end)
        if not ok then return end
        for i = 1, #list do
            pcall(hook, list[i])
            if i % 150 == 0 then task.wait() end
        end
    end)
end

local scanState = {}   -- 顶层 GUI -> { count, nextAt, dirty }

-- 判断一个顶层界面是不是脚本界面，是就交给 confirmHub 处理
-- 这个函数会被反复调用（启动时、有新界面时、每秒定时），所以里面限制了检查频率
local function considerTop(top)
    if hubTop[top] or isOwnGui(top) then return end

    -- 未知游戏（汉化表为空）：脚本加载后新出现的界面直接当作脚本界面
    if not HasGameTexts then
        if not preexisting[top] then confirmHub(top) end
        return
    end

    -- 这个界面的检查记录：
    -- count 已检查次数；nextAt 下次最早检查时间；dirty 是否有新增控件；once 原有界面（如执行器）只检查一次
    local st = scanState[top]
    if not st then
        st = { count = 0, nextAt = 0, dirty = true, once = preexisting[top], busy = false }
        scanState[top] = st
        -- 新出现的界面：里面有新增控件就标记，稍后再检查（界面通常是先创建、后填字）
        if not st.once then
            pcall(function()
                top.DescendantAdded:Connect(function() st.dirty = true end)
            end)
        end
    end

    -- 下面是限频规则：太频繁、检查次数太多、原有界面已查过、没有变化，都跳过
    local now = os.clock()
    if now < st.nextAt then return end
    if st.busy then return end                            -- 上一次检查还没结束（界面很大时会分帧）
    if st.count >= 60 then return end
    if st.once and st.count >= 1 then return end          -- 原有界面（如执行器）只检查一次
    if not (st.dirty or st.count < 8) then return end

    -- 开始一次检查（下面记录次数和下次时间）
    st.dirty = false
    st.count = st.count + 1
    st.nextAt = now + 1.5

    -- 顶层界面里出现了当前游戏汉化表里的文字，才算脚本界面
    st.busy = true
    local ok, found = pcall(containsGameText, top)
    st.busy = false
    if ok and found then
        confirmHub(top)
    end
end

-- 启动汉化监听
-- HubOnly = true ：只监听顶层界面，识别出脚本界面后才挂钩（快）
-- HubOnly = false：监听所有界面（旧方式，会处理游戏和执行器的界面，较慢）
local function startWatching()
    if not HubOnly then
        for _, root in ipairs(getRoots()) do watch(root) end
        return
    end

    for _, root in ipairs(getRoots()) do
        pcall(function()
            root.ChildAdded:Connect(function(top) task.defer(considerTop, top) end)
            -- 启动时的首轮检查放到独立线程，不拖慢后面加载 hub
            task.spawn(function()
                for _, top in ipairs(root:GetChildren()) do considerTop(top) end
            end)
        end)
    end

    -- 定时检查：兜住"界面先创建、之后才填字"的情况
    task.spawn(function()
        while true do
            task.wait(1)
            for _, root in ipairs(getRoots()) do
                pcall(function()
                    for _, top in ipairs(root:GetChildren()) do considerTop(top) end
                end)
            end
        end
    end)
end

------------------------------------------------------------------
-- 签名：小胶囊，彩虹渐变（位置见 SignaturePosition）；点击（或按 ToggleKey）开/关汉化
------------------------------------------------------------------
-- 更新提示文字：发现新版本时会追加到签名上
local UpdateNotice = ""

-- 检查更新：UpdateURL 为空就不检查
-- 在后台线程下载线上脚本，比较版本号，不同就调用 onNewVersion 回调
local function checkUpdate(onNewVersion)
    if not UpdateURL then return end
    task.spawn(function()
        local ok, body = pcall(function() return game:HttpGet(UpdateURL) end)
        if ok and type(body) == "string" then
            local remote = body:match('local ScriptVersion = "([%d%.]+)"')
            if remote and remote ~= ScriptVersion then
                onNewVersion(remote)
            end
        end
    end)
end

-- 签名位置预设：{ 锚点, 位置 }，离屏幕边缘 8 像素。想加新位置就在这里加一行
local SIGNATURE_LAYOUT = {
    TopLeft      = { Vector2.new(0, 0),   UDim2.new(0, 8, 0, 8) },
    TopCenter    = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8) },
    TopRight     = { Vector2.new(1, 0),   UDim2.new(1, -8, 0, 8) },
    BottomLeft   = { Vector2.new(0, 1),   UDim2.new(0, 8, 1, -8) },
    BottomCenter = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -8) },
    BottomRight  = { Vector2.new(1, 1),   UDim2.new(1, -8, 1, -8) },
}

-- 彩虹色渐变（7 个关键点，首尾同色，所以旋转起来是无缝循环）
local function rainbowSequence()
    local points = {}
    for i = 0, 6 do
        table.insert(points, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i % 6) / 6, 0.75, 1)))
    end
    return ColorSequence.new(points)
end

-- 让渐变一直旋转：交给 TweenService 在引擎里循环（repeatCount = -1 表示无限），
-- 不需要每帧运行任何 Lua 代码，所以 240 帧下也没有额外开销
local function spinGradient(gradient, seconds)
    local info = TweenInfo.new(seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
    local tween = game:GetService("TweenService"):Create(gradient, info, { Rotation = 360 })
    tween:Play()
end

-- 创建签名胶囊：显示汉化名称、版本和开关状态
-- 点击胶囊或按 ToggleKey 可以开/关汉化。想改署名文字，改下面 refreshText 里的字符串
local function createRGBSignature()
    if not LocalPlayer then return end

    local parent
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then parent = hui end
    end
    parent = parent or LocalPlayer:WaitForChild("PlayerGui")

    -- 签名所在的 ScreenGui，放在 gethui 或 PlayerGui 里
    local gui = Instance.new("ScreenGui")
    gui.Name = "EternalSignature"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 998
    gui.Parent = parent

    local layout = SIGNATURE_LAYOUT[SignaturePosition] or SIGNATURE_LAYOUT.TopRight

    -- 背景胶囊：只负责底色、圆角和描边，宽度随里面的文字自动变化
    local pill = Instance.new("Frame")
    pill.AnchorPoint = layout[1]
    pill.Position = layout[2]
    pill.Size = UDim2.new(0, 0, 0, 26)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    pill.BackgroundTransparency = 0.25
    pill.BorderSizePixel = 0
    pill.Parent = gui

    -- 圆角，半径取最大就是胶囊形
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = pill

    -- 描边：底色是白色，颜色完全来自彩虹渐变
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Parent = pill

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = rainbowSequence()
    strokeGradient.Parent = stroke
    spinGradient(strokeGradient, 4)

    -- 文字按钮：背景透明，渐变只会染到文字上；点击它开/关汉化
    local label = Instance.new("TextButton")
    label.AutoButtonColor = false
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 0, 1, 0)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Parent = pill

    -- 左右内边距，文字不贴边
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = label

    local textGradient = Instance.new("UIGradient")
    textGradient.Color = rainbowSequence()
    textGradient.Parent = label
    spinGradient(textGradient, 6)

    -- 刷新文字：显示开/关和更新提示；关闭汉化时文字变淡
    local function refreshText()
        label.Text = "永恒汉化 · v" .. ScriptVersion .. " · " .. (translationEnabled and "开" or "关") .. UpdateNotice
        label.TextTransparency = translationEnabled and 0 or 0.45
    end
    refreshText()

    -- 切换汉化开关，并刷新文字
    local function toggle()
        setTranslationEnabled(not translationEnabled)
        refreshText()
    end
    label.MouseButton1Click:Connect(toggle)

    -- 键盘快捷键（电脑用；手机点胶囊即可）。界面销毁后自动断开监听
    local UserInputService = game:GetService("UserInputService")
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if not gui.Parent then
            inputConn:Disconnect()
            return
        end
        if processed then return end
        if input.KeyCode == ToggleKey then toggle() end
    end)

    -- 后台检查更新，有新版本就在胶囊上提示
    checkUpdate(function(remote)
        UpdateNotice = " · 有新版 v" .. remote
        refreshText()
    end)
end

------------------------------------------------------------------
-- 启动
------------------------------------------------------------------
-- 启动流程：先启动汉化监听（最重要），再创建签名
-- 每一步都用 pcall 单独保护，某一步出错不会影响其他步骤，也不会影响 hub 加载
local function startTranslation()
    -- 先启动汉化监听（最重要），其他界面放到独立线程里，出错也不影响
    local ok, err = pcall(startWatching)
    if not ok then warn("汉化监听启动失败:", err) end

--@DEV_BEGIN
    -- 设置帧率上限：只是把上限调高，实际帧率取决于设备性能和执行器
    if FpsCap and type(setfpscap) == "function" then
        pcall(setfpscap, FpsCap)
    end

    task.spawn(function()
        local ok2, err2 = pcall(createMissingUI)
        if not ok2 then warn("漏翻窗口创建失败:", err2) end
    end)
--@DEV_END

    task.spawn(function()
        local ok3, err3 = pcall(createRGBSignature)
        if not ok3 then warn("签名创建失败:", err3) end
    end)
end

-- 加载 hub：远程执行 loader.lua。用 pcall 保护，加载失败只警告，不影响汉化
local function loadScript()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://hoshihub.site/loader.lua"))()
    end)
    if not success then
        warn("加载失败:", err)
    end
end

takeSnapshot() -- 必须在加载脚本之前

-- 按 RunScriptFirst 决定启动顺序（见文件开头）
if RunScriptFirst then
    loadScript()
    task.wait(2)
    startTranslation()
else
    startTranslation()
    loadScript()
end
