local addonName, ns = ...
ns.VERSION = "1.0.2"
ns.AUTHOR = "meinyrdi"
local tracked = setmetatable({}, { __mode = "k" })

-- Tooltip values can be secret on Forever. Leave those rows to Blizzard.
local function accessible(...)
    if canaccessallvalues then return canaccessallvalues(...) end
    if issecretvalue then
        for i = 1, select("#", ...) do
            if issecretvalue(select(i, ...)) then return false end
        end
    end
    return true
end

local function finite(value)
    return accessible(value) and type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

local function integer(value, minimum)
    return finite(value) and value >= minimum and value == math.floor(value)
end

local function bagSource(tooltip, processing)
    if tooltip:IsForbidden() then return end
    local info
    if processing then
        info = tooltip:GetProcessingTooltipInfo()
    else
        info = tooltip:GetPrimaryTooltipInfo()
    end
    if not accessible(info) or type(info) ~= "table" then return end
    if not accessible(info.getterName, info.getterArgs, info.append) then return end
    -- Appended/nested items and other contexts keep their native prices.
    if info.getterName ~= "GetBagItem" or info.append or type(info.getterArgs) ~= "table" then return end
    local bag, slot = info.getterArgs[1], info.getterArgs[2]
    if integer(bag, -100) and integer(slot, 1) then return bag, slot end
end

function ns:RefreshTooltips()
    for tooltip in pairs(tracked) do
        if not tooltip:IsForbidden() and tooltip:IsShown() and bagSource(tooltip, false) ~= nil then
            -- Rebuild through the normal owner/update path, outside our callback.
            tooltip:RefreshDataNextUpdate()
        end
    end
end

function ns:SetOption(key, value)
    if not self.db then return end
    if key == "showBoth" or key == "showMinimap" then
        if type(value) ~= "boolean" then return end
    elseif key == "minimapAngle" then
        if not accessible(value) or type(value) ~= "number" or value ~= value
            or math.abs(value) == math.huge then return end
        value = value % 360
    else
        return
    end
    self.db[key] = value
    if key == "showBoth" then self:RefreshTooltips() end
    if self.RefreshUI then self:RefreshUI() end
end

local function sellPrice(tooltip, line)
    if not ns.db or not tooltip.GetProcessingTooltipInfo or not tooltip.GetPrimaryTooltipInfo
        or not tooltip.RefreshDataNextUpdate then return end
    if not accessible(tooltip.isShopping, line.price, line.maxPrice) or tooltip.isShopping then return end
    if not integer(line.price, 1) then return end
    -- Match Blizzard's actual branch: nil or maxPrice < 1 is one price.
    -- Forever uses -1 for a normal quote; it is not an invalid range.
    if line.maxPrice ~= nil and (not finite(line.maxPrice) or line.maxPrice >= 1) then return end
    local bag, slot = bagSource(tooltip, true)
    if bag == nil then return end
    local item = C_Container.GetContainerItemInfo(bag, slot)
    if not accessible(item) or type(item) ~= "table" then return end
    local count = item.stackCount
    if not accessible(item.hasNoValue) or item.hasNoValue or not integer(count, 1) then return end
    local total = line.price
    local unit = total / count
    -- Never invent a fractional copper amount or guess from cached item data.
    if not integer(unit, 1) then return end
    tracked[tooltip] = true
    if count == 1 then return end

    if ns.db.showBoth then
        local eachText = MoneyFormatterUtil.FormatMoney(unit, GameTooltipMoneyFormat)
        local stackText = MoneyFormatterUtil.FormatMoney(total, GameTooltipMoneyFormat)
        GameTooltip_AddHighlightLine(tooltip,
            string.format("%s: %s each / %s stack (%d)", SELL_PRICE, eachText, stackText, count))
    else
        GameTooltip_OnTooltipAddMoney(tooltip, IsShiftKeyDown() and total or unit)
    end
    -- Consume this row so Blizzard does not add a second Sell Price line.
    -- Do not modify line.price: it must remain the stack total on every rebuild.
    return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        if WOW_PROJECT_ID ~= (WOW_PROJECT_CAMELOT or 18) then return end
        local saved = type(SimpleSellPriceDB) == "table" and SimpleSellPriceDB or {}
        if type(saved.showBoth) ~= "boolean" then saved.showBoth = false end
        if type(saved.showMinimap) ~= "boolean" then saved.showMinimap = true end
        if type(saved.minimapAngle) ~= "number" or saved.minimapAngle ~= saved.minimapAngle
            or math.abs(saved.minimapAngle) == math.huge then saved.minimapAngle = 225 end
        saved.minimapAngle = saved.minimapAngle % 360
        SimpleSellPriceDB = saved
        ns.db = saved
        TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.SellPrice, sellPrice)
        ns:InitializeUI()
        SLASH_SIMPLESELLPRICE1 = "/ssp"
        SLASH_SIMPLESELLPRICE2 = "/simplesellprice"
        SlashCmdList.SIMPLESELLPRICE = function() ns:ToggleSettings() end
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
        self:RegisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "MODIFIER_STATE_CHANGED" then
        local key = ...
        if key == "LSHIFT" or key == "RSHIFT" then ns:RefreshTooltips() end
    elseif event == "BAG_UPDATE_DELAYED" then
        ns:RefreshTooltips()
    end
end)
