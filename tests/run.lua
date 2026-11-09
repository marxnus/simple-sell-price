-- Behavioral tests through the packaged TOC and real UI/event callbacks.
local runtime = arg[1] or "SimpleSellPrice"
local checks = 0
local function check(condition, message)
    assert(condition, message)
    checks = checks + 1
end
local function equal(actual, expected, message)
    check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function client(saved, project, noMinimap)
    local env = setmetatable({}, { __index = _G })
    local frames, objects, callbacks = {}, {}, {}
    local ns, state = {}, { shift = false, queries = 0, items = {} }
    local Frame = {}
    local function frame()
        local f = setmetatable({ shown = true, scripts = {}, events = {}, points = {}, rows = {} }, { __index = Frame })
        frames[#frames + 1] = f
        return f
    end
    function Frame:SetScript(event, func) self.scripts[event] = func end
    function Frame:HookScript(event, func) self.scripts[event] = func end
    function Frame:RegisterEvent(event) self.events[event] = true end
    function Frame:UnregisterEvent(event) self.events[event] = nil end
    function Frame:SetShown(value)
        value = not not value
        if value == self.shown then return end
        self.shown = value
        local handler = self.scripts[value and "OnShow" or "OnHide"]
        if handler then handler(self) end
    end
    function Frame:Show() self:SetShown(true) end
    function Frame:Hide() self:SetShown(false) end
    function Frame:IsShown()
        assert(not self.forbidden, "IsShown called on forbidden frame")
        return self.shown
    end
    function Frame:IsForbidden() return self.forbidden end
    function Frame:SetText(text) self.text = text end
    function Frame:AddLine(text) self.rows[#self.rows + 1] = text end
    function Frame:SetChecked(value) self.checked = value end
    function Frame:GetChecked() return self.checked end
    function Frame:SetPoint(...) self.points[#self.points + 1] = {...} end
    function Frame:ClearAllPoints() self.points = {} end
    function Frame:SetSize(w, h) self.width, self.height = w, h end
    function Frame:SetWidth(w) self.width = w end
    function Frame:SetHeight(h) self.height = h end
    function Frame:GetWidth() return self.width or 140 end
    function Frame:GetHeight() return self.height or 140 end
    function Frame:GetCenter() return 500, 500 end
    function Frame:GetEffectiveScale() return 1 end
    function Frame:CreateTexture() return frame() end
    function Frame:CreateFontString() return frame() end
    function Frame:StartMoving() self.moving = true end
    function Frame:StopMovingOrSizing() self.moving = false end
    function Frame:SetOwner(owner) self.owner = owner end
    function Frame:IsOwned(owner) return self.owner == owner end
    function Frame:GetProcessingTooltipInfo() return self.processing end
    function Frame:GetPrimaryTooltipInfo() return self.primary end
    function Frame:RefreshDataNextUpdate() self.pending = true; self.refreshes = (self.refreshes or 0) + 1 end
    for _, method in ipairs({ "SetFrameStrata", "SetClampedToScreen", "RegisterForClicks", "RegisterForDrag",
        "SetTexture", "SetTexCoord", "SetHighlightTexture", "SetFontObject", "SetHitRectInsets",
        "SetMovable", "EnableMouse", "SetJustifyH" }) do
        Frame[method] = function() end
    end
    function env.CreateFrame(kind, name, parent, template)
        local f = frame()
        f.parent, f.template = parent, template
        if name then objects[name] = f; env[name] = f end
        if template == "BasicFrameTemplateWithInset" then
            f.TitleText = frame()
            f.CloseButton = frame()
            f.CloseButton:SetScript("OnClick", function() f:Hide() end)
        elseif template == "UICheckButtonTemplate" then
            f.Text = frame()
        end
        return f
    end
    env.UIParent, env.Minimap = frame(), not noMinimap and frame() or nil
    env.GameTooltip, env.UISpecialFrames, env.SlashCmdList = frame(), {}, {}
    env.SimpleSellPriceDB = saved
    env.WOW_PROJECT_ID, env.WOW_PROJECT_CAMELOT = project or 18, 18
    env.Enum = { TooltipDataLineType = { SellPrice = 11 } }
    env.TooltipDataProcessor = { AddLinePreCall = function(kind, callback)
        equal(kind, 11, "registered the sell-price line callback")
        callbacks[#callbacks + 1] = callback
    end }
    env.C_Container = { GetContainerItemInfo = function(bag, slot)
        state.queries = state.queries + 1
        return state.items[bag .. ":" .. slot]
    end }
    env.IsShiftKeyDown = function() return state.shift end
    env.GetCursorPosition = function() return 500, 700 end
    env.issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    env.canaccessallvalues = function(...)
        for i = 1, select("#", ...) do
            if env.issecretvalue(select(i, ...)) then return false end
        end
        return true
    end
    env.SELL_PRICE = "Sell Price"
    env.GameTooltipMoneyFormat = {}
    env.MoneyFormatterUtil = { FormatMoney = function(amount) return amount .. "c" end }
    env.GameTooltip_AddHighlightLine = function(tooltip, text) tooltip:AddLine(text) end
    env.GameTooltip_OnTooltipAddMoney = function(tooltip, price, maximum)
        tooltip.nativeAmount, tooltip.nativeMaximum = price, maximum
        tooltip:AddLine(env.SELL_PRICE .. ": " .. env.MoneyFormatterUtil.FormatMoney(price))
    end
    function state:event(event, ...)
        for _, f in ipairs(frames) do
            if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end
    function state:tooltip(getter, bag, slot)
        local t = frame()
        t.primary = { getterName = getter or "GetBagItem", getterArgs = { bag or 0, slot or 1 } }
        t.processing = t.primary
        return t
    end
    function state:render(tooltip, line)
        tooltip.rows, tooltip.nativeAmount, tooltip.nativeMaximum = {}, nil, nil
        local consumed
        for _, callback in ipairs(callbacks) do
            if callback(tooltip, line) then consumed = true; break end
        end
        if not consumed then env.GameTooltip_OnTooltipAddMoney(tooltip, line.price, line.maxPrice) end
        return consumed
    end
    function state:update(tooltip, line)
        if tooltip.pending then
            tooltip.pending = false
            self:render(tooltip, line)
        end
    end
    function state:click(frameObject)
        if frameObject.scripts.OnMouseDown then frameObject.scripts.OnMouseDown(frameObject, "LeftButton") end
        frameObject.scripts.OnClick(frameObject, "LeftButton")
    end
    local toc = assert(io.open(runtime .. "/SimpleSellPrice.toc"))
    for line in toc:lines() do
        if line:match("%.lua$") then
            local chunk = assert(loadfile(runtime .. "/" .. line))
            setfenv(chunk, env)("SimpleSellPrice", ns)
        end
    end
    toc:close()
    state.env, state.ns, state.objects, state.callbacks = env, ns, objects, callbacks
    return state
end

local c = client()
c:event("ADDON_LOADED", "AnotherAddon")
equal(#c.callbacks, 0, "waits for own addon load")
c:event("ADDON_LOADED", "SimpleSellPrice")
equal(c.ns.db.showBoth, false, "unit-only default")
equal(c.ns.db.showMinimap, true, "launcher default")
equal(c.ns.db.minimapAngle, 225, "launcher angle default")
equal(#c.callbacks, 1, "one tooltip callback")
c:event("ADDON_LOADED", "SimpleSellPrice")
equal(#c.callbacks, 1, "no duplicate registration")

c.items["0:1"] = { stackCount = 20, hasNoValue = false }
-- Observed on the user's Forever client: an ordinary quote has maxPrice=-1.
-- Native rendering accepts every finite maxPrice < 1 as a single price.
local tooltip, line = c:tooltip(), { price = 3000, maxPrice = -1 }
check(c:render(tooltip, line), "stack row replaced")
equal(tooltip.nativeAmount, 150, "normal hover unit value")
equal(#tooltip.rows, 1, "same single sell-price row")
equal(line.price, 3000, "raw total not mutated")
for _, maximum in ipairs({ 0, -1, -2, 0.5 }) do
    line.maxPrice = maximum
    check(c:render(tooltip, line), "single-price max sentinel accepted: " .. maximum)
    equal(tooltip.nativeAmount, 150, "single-price sentinel retains unit value")
end
line.maxPrice = nil
check(c:render(tooltip, line), "missing maxPrice remains supported")
line.maxPrice = -1
for i = 1, 5 do c:render(tooltip, line) end
equal(tooltip.nativeAmount, 150, "repeated rebuild never divides twice")
c.shift = true
c:event("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(tooltip.pending, "stationary press schedules native refresh")
equal(tooltip.nativeAmount, 150, "no recursive rendering in modifier event")
c:update(tooltip, line)
equal(tooltip.nativeAmount, 3000, "Shift displays actual stack total")
equal(#tooltip.rows, 1, "Shift keeps one row")
c.shift = false
c:event("MODIFIER_STATE_CHANGED", "RSHIFT", 0)
c:update(tooltip, line)
equal(tooltip.nativeAmount, 150, "release restores unit price")
tooltip.pending = nil
c:event("MODIFIER_STATE_CHANGED", "LCTRL", 1)
check(not tooltip.pending, "irrelevant modifiers do not refresh")
c.shift = true
c:render(tooltip, line)
equal(tooltip.nativeAmount, 3000, "Shift already held on initial hover")

local window = c.objects.SimpleSellPriceSettings
local button = c.objects.SimpleSellPriceMinimapButton
check(not window:IsShown(), "settings starts closed")
check(button:IsShown(), "minimap starts shown")
c:click(button)
check(window:IsShown(), "minimap click opens settings")
window.showBoth:SetChecked(true)
c:click(window.showBoth)
check(c.ns.db.showBoth and tooltip.pending, "checkbox persists both and refreshes")
c:update(tooltip, line)
equal(#tooltip.rows, 1, "both mode also uses the same row")
equal(tooltip.rows[1], "Sell Price: 150c each / 3000c stack (20)", "both mode labels values and actual count")
c.shift = false
c:render(tooltip, line)
equal(tooltip.rows[1], "Sell Price: 150c each / 3000c stack (20)", "both mode stable without Shift")

c.items["0:1"].stackCount = 5
line.price = 750
c:event("BAG_UPDATE_DELAYED")
c:update(tooltip, line)
equal(tooltip.rows[1], "Sell Price: 150c each / 750c stack (5)", "stack split reflected while hovered")
c.items["0:1"].stackCount = 1
line.price = 150
check(not c:render(tooltip, line), "single item retains native row")
equal(#tooltip.rows, 1, "single item has no redundant both row")

window.showMinimap:SetChecked(false)
c:click(window.showMinimap)
check(not button:IsShown(), "checkbox hides minimap button")
c.env.SlashCmdList.SIMPLESELLPRICE()
check(not window:IsShown(), "slash toggles window closed")
c.env.SlashCmdList.SIMPLESELLPRICE()
check(window:IsShown(), "slash recovers settings while button hidden")
equal(c.env.SLASH_SIMPLESELLPRICE1, "/ssp", "short slash command")
equal(c.env.SLASH_SIMPLESELLPRICE2, "/simplesellprice", "long slash command")
equal(c.env.UISpecialFrames[1], "SimpleSellPriceSettings", "Escape registration")
c:click(window.CloseButton)
check(not window:IsShown(), "native close button closes")
c.ns:SetOption("showMinimap", true)
c:click(button)
button.scripts.OnDragStart(button)
check(button.dragging and button.scripts.OnUpdate, "drag begins temporary update loop")
button.scripts.OnUpdate(button)
equal(c.ns.db.minimapAngle, 225, "angle is not saved on every drag frame")
button.scripts.OnDragStop(button)
equal(c.ns.db.minimapAngle, 90, "drag release saves angle")
check(not button.dragging and not button.scripts.OnUpdate, "drag loop stops")
button.scripts.OnClick(button)
check(window:IsShown(), "drag-release click does not toggle settings")
c:click(button)
check(not window:IsShown(), "next ordinary click works")
button.scripts.OnEnter(button)
check(c.env.GameTooltip:IsOwned(button) and c.env.GameTooltip:IsShown(), "launcher hover help")
button.scripts.OnLeave(button)
check(not c.env.GameTooltip:IsShown(), "launcher hover cleaned up")

local function untouched(label, change)
    c.items["0:1"] = { stackCount = 20 }
    local t, l = c:tooltip(), { price = 3000 }
    change(t, l)
    check(not c:render(t, l), label)
end
untouched("merchant purchase unchanged", function(t) t.processing.getterName = "GetMerchantItem" end)
untouched("chat link unchanged", function(t) t.processing.getterName = "GetHyperlink" end)
untouched("comparison tooltip unchanged", function(t) t.isShopping = true end)
untouched("appended item unchanged", function(t) t.processing.append = true end)
untouched("processing source used instead of primary item", function(t)
    t.processing = { getterName = "GetItemByID", getterArgs = { 4306 } }
end)
untouched("uncached/missing bag item unchanged", function() c.items["0:1"] = nil end)
untouched("missing stack count unchanged", function() c.items["0:1"].stackCount = nil end)
untouched("zero stack count unchanged", function() c.items["0:1"].stackCount = 0 end)
untouched("non-integral stack count unchanged", function() c.items["0:1"].stackCount = 1.5 end)
untouched("no-value item unchanged", function() c.items["0:1"].hasNoValue = true end)
untouched("zero vendor value unchanged", function(_, l) l.price = 0 end)
untouched("ranged price unchanged", function(_, l) l.maxPrice = 4000 end)
untouched("range boundary unchanged", function(_, l) l.maxPrice = 1 end)
untouched("NaN maximum unchanged", function(_, l) l.maxPrice = 0 / 0 end)
untouched("infinite maximum unchanged", function(_, l) l.maxPrice = math.huge end)
untouched("negative infinite maximum unchanged", function(_, l) l.maxPrice = -math.huge end)
untouched("non-integral copper unchanged", function(_, l) l.price = 3001 end)
untouched("forbidden tooltip untouched", function(t) t.forbidden = true end)

-- Opaque sentinels fail if arithmetic/comparison/string conversion is attempted.
local function secret()
    local function fail() error("attempted to inspect a secret value") end
    return setmetatable({ secret = true }, { __lt = fail, __le = fail, __div = fail, __tostring = fail })
end
for _, field in ipairs({ "price", "maxPrice" }) do
    local t, l = c:tooltip(), { price = 3000 }
    l[field] = secret()
    check(not c.callbacks[1](t, l), "secret " .. field .. " left to native callback")
end
for _, field in ipairs({ "stackCount", "hasNoValue" }) do
    c.items["0:1"] = { stackCount = 20 }
    c.items["0:1"][field] = secret()
    check(not c.callbacks[1](c:tooltip(), { price = 3000 }), "secret " .. field .. " left untouched")
end
local hidden = c:tooltip()
hidden.processing.getterArgs[1] = secret()
local queries = c.queries
check(not c.callbacks[1](hidden, { price = 3000 }), "secret bag ID untouched")
equal(c.queries, queries, "secret arguments never reach container API")
tooltip.forbidden = true
c:event("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(true, "tracked tooltip becoming forbidden is safe")
tooltip.forbidden = false
tooltip.primary.getterName = "GetUnit"
tooltip.pending = nil
c:event("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
check(not tooltip.pending, "tooltip reused for a unit is not rebuilt")

c.ns:SetOption("showBoth", "wrong")
equal(c.ns.db.showBoth, true, "invalid setting ignored")
c.ns:SetOption("minimapAngle", 450)
equal(c.ns.db.minimapAngle, 90, "angle normalized")
c.ns:SetOption("minimapAngle", 0 / 0)
equal(c.ns.db.minimapAngle, 90, "NaN angle rejected")
c.ns:SetOption("unknown", true)
equal(c.ns.db.unknown, nil, "unknown setting ignored")

local reload = client(c.env.SimpleSellPriceDB)
reload:event("ADDON_LOADED", "SimpleSellPrice")
equal(reload.ns.db.showBoth, true, "both persists across reload")
equal(reload.ns.db.minimapAngle, 90, "launcher position persists across reload")
local corrupted = client({ showBoth = "yes", showMinimap = 0, minimapAngle = math.huge })
corrupted:event("ADDON_LOADED", "SimpleSellPrice")
equal(corrupted.ns.db.showBoth, false, "invalid saved mode repaired")
equal(corrupted.ns.db.showMinimap, true, "invalid saved launcher setting repaired")
equal(corrupted.ns.db.minimapAngle, 225, "invalid saved angle repaired")
local missing = client(false, 18, true)
missing:event("ADDON_LOADED", "SimpleSellPrice")
check(missing.objects.SimpleSellPriceMinimapButton:IsShown(), "fallback launcher if minimap absent")
local other = client(nil, 1)
other:event("ADDON_LOADED", "SimpleSellPrice")
equal(#other.callbacks, 0, "other game projects not modified")
equal(other.objects.SimpleSellPriceSettings, nil, "other game UI not created")

print("Simple Sell Price: " .. checks .. " behavioral checks passed")
