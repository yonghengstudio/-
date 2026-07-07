local RunScriptFirst = false

local Translations = {
    ["Tycoon"] = "基地",
    ["Progression"] = "进阶",
    ["Performance"] = "性能",
    ["Settings"] = "设置",
    ["key"] = "密钥"
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

local function translateText(text)
    if not text or type(text) ~= "string" then return text end
    if Translations[text] then return Translations[text] end
    for en, cn in pairs(Translations) do
        if text:find(en) then return text:gsub(en, cn) end
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
