-- chekushka_ru.lua
-- Chekushka 1.2 (русская версия)

-- Версия 1.2
local UIS = game:GetService("UserInputService")
local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled)
local isPC = UIS.KeyboardEnabled

local ActiveCoroutines = {}
local ScriptLoaded = true
local BlockDropNotifications = false

local SelectedCustomCases = {}
local ProfitCases = {"Manager", "Plodder", "Director", "Office Clerk", "Gold", "Oligarch", "Trash", "Beggar"}

local AllCases = {
    "Trash", "Daily",
    "Beggar", "Plodder", "Office Clerk", "Manager", "Director", "Oligarch",
    "Frozen Heart", "Bubble Gum", "Cats", "Glitch", "Dream", "Bloody Night",
    "M5 F90", "G63", "Porsche 911", "URUS",
    "Gold", "Dark", "Palm", "Burj", "Luxury"
}

local CaseFunctions = {
    OpenCase = function(caseType, amount)
        if not ScriptLoaded then return end
        local args = {[1] = caseType, [2] = amount}
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("OpenCase"):InvokeServer(unpack(args))
    end
}

local function SetupDropBlock()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local DropEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Drop")
    for _, connection in pairs(getconnections(DropEvent.OnClientEvent)) do
        pcall(function() connection:Disable() end)
    end
end

local function UpdateDropBlocking()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local DropEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Drop")
    for _, connection in pairs(getconnections(DropEvent.OnClientEvent)) do
        pcall(function()
            if BlockDropNotifications then connection:Disable() else connection:Enable() end
        end)
    end
end

local function StopAllProcesses()
    if not ScriptLoaded then return end
    ScriptLoaded = false
    ActiveCoroutines.AutoOpenCase = false
    ActiveCoroutines.AutoSellAll = false
    ActiveCoroutines.AutoProfitCases = false
    ActiveCoroutines.AutoCustomCases = false
end

local function StartAutoOpenProfit()
    if ActiveCoroutines.AutoProfitCases or not ScriptLoaded then return end
    ActiveCoroutines.AutoProfitCases = true
    coroutine.wrap(function()
        while ActiveCoroutines.AutoProfitCases and ScriptLoaded do
            for _, caseName in ipairs(ProfitCases) do
                CaseFunctions.OpenCase(caseName, 10)
                task.wait(0.1)
            end
        end
        ActiveCoroutines.AutoProfitCases = nil
    end)()
end

local function StopAutoOpenProfit() ActiveCoroutines.AutoProfitCases = false end

local function StartAutoOpenCustom()
    if ActiveCoroutines.AutoCustomCases or not ScriptLoaded then return end
    ActiveCoroutines.AutoCustomCases = true
    coroutine.wrap(function()
        while ActiveCoroutines.AutoCustomCases and ScriptLoaded do
            for _, caseName in ipairs(SelectedCustomCases) do
                CaseFunctions.OpenCase(caseName, 10)
                task.wait(0.1)
            end
        end
        ActiveCoroutines.AutoCustomCases = nil
    end)()
end

local function StopAutoOpenCustom() ActiveCoroutines.AutoCustomCases = false end

local function StartAutoSell()
    if ActiveCoroutines.AutoSellAll or not ScriptLoaded then return end
    ActiveCoroutines.AutoSellAll = true
    coroutine.wrap(function()
        while ActiveCoroutines.AutoSellAll and ScriptLoaded do
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Inventory"):FireServer("Sell", "ALL")
            task.wait(0.5)
        end
        ActiveCoroutines.AutoSellAll = nil
    end)()
end

local function StopAutoSell() ActiveCoroutines.AutoSellAll = false end

-- Загрузка Rayfield
local function LoadRayfield()
    local urls = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/AlexR32/Rayfield/main/source.lua"
    }
    for _, url in ipairs(urls) do
        local ok, lib = pcall(function() return loadstring(game:HttpGet(url))() end)
        if ok and lib then return lib end
    end
    return nil
end

local Rayfield = LoadRayfield()
if not Rayfield then
    warn("Rayfield не загружен.")
    return
end

local windowName = isMobile and "Chekushka Mobile 1.2" or "Chekushka 1.2"
local Window = Rayfield:CreateWindow({
    Name = windowName,
    LoadingTitle = "Chekushka Script",
    LoadingSubtitle = "by rodr3x",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false
})

local MainTab = Window:CreateTab("Главная", nil)
MainTab:CreateSection("Авто-открытие кейсов")

MainTab:CreateToggle({
    Name = "Авто открытие окупных кейсов",
    CurrentValue = false,
    Flag = "AutoProfitCases",
    Callback = function(Value)
        if Value then
            StartAutoOpenProfit()
            Rayfield:Notify({Title = "Auto Profit Cases", Content = "Открываются: Manager, Plodder, Director, Office Clerk, Gold, Oligarch, Trash, Beggar", Duration = 5})
        else
            StopAutoOpenProfit()
            Rayfield:Notify({Title = "Auto Profit Cases", Content = "Остановлено авто открытие прибыльных кейсов", Duration = 4})
        end
    end,
})

MainTab:CreateLabel("100% окупные кейсы")

local CustomDropdown = MainTab:CreateDropdown({
    Name = "Выберите кейсы",
    Options = AllCases,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "CustomCaseSelection",
    Callback = function(Values)
        SelectedCustomCases = Values
        local selectedText = "none"
        if #Values > 0 then selectedText = table.concat(Values, ", ") end
        Rayfield:Notify({Title = "Выбор кейсов обновлён", Content = selectedText, Duration = 5})
    end,
})

MainTab:CreateToggle({
    Name = "Авто открытие выбранных кейсов",
    CurrentValue = false,
    Flag = "AutoCustomCases",
    Callback = function(Value)
        if Value then
            if #SelectedCustomCases == 0 then
                Rayfield:Notify({Title = "Ошибка", Content = "Кейсы не выбраны!", Duration = 4})
                return
            end
            StartAutoOpenCustom()
            Rayfield:Notify({Title = "Auto Custom Cases", Content = "Открываются: " .. table.concat(SelectedCustomCases, ", "), Duration = 5})
        else
            StopAutoOpenCustom()
            Rayfield:Notify({Title = "Auto Custom Cases", Content = "Остановлено открытие выбранных кейсов", Duration = 4})
        end
    end,
})

MainTab:CreateSection("Автоматизация")
MainTab:CreateToggle({
    Name = "Авто продажа",
    CurrentValue = false,
    Flag = "AutoSellAll",
    Callback = function(Value) if Value then StartAutoSell() else StopAutoSell() end end,
})

MainTab:CreateSection("Оптимизация")
MainTab:CreateToggle({
    Name = "Блокировать уведомления о дропах",
    CurrentValue = false,
    Flag = "BlockDropNotifications",
    Callback = function(Value) BlockDropNotifications = Value UpdateDropBlocking() end,
})

MainTab:CreateSection("Утилиты")
MainTab:CreateButton({
    Name = "Выгрузить скрипт",
    Callback = function()
        StopAllProcesses()
        Rayfield:Notify({Title = "Скрипт выгружен", Content = "Все функции остановлены и скрипт выгружен", Duration = 5})
        task.wait(2)
        pcall(function() Rayfield:Destroy() end)
    end,
})

MainTab:CreateSection("Информация")
MainTab:CreateLabel("t.me/rodr3x для помощи/идей")
MainTab:CreateLabel("Официальные продавцы FunPay: Dan7755, Mars22852")
MainTab:CreateLabel("Прибыльные кейсы: Manager, Plodder, Director, Office Clerk, Gold, Oligarch, Trash, Beggar")

Rayfield:Notify({Title = "Chekushka 1.2 загружен", Content = "Успешно загружен с выбором кейсов!", Duration = 6})

task.wait(2)
SetupDropBlock()

game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then StopAllProcesses() end
end)
