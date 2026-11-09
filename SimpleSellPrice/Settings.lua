local _, ns = ...

local window, minimapButton

local function number(value)
    return (not issecretvalue or not issecretvalue(value)) and type(value) == "number"
        and value == value and math.abs(value) < math.huge
end

local function hideTooltip(owner)
    if GameTooltip and GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

local function positionButton(angle)
    if not minimapButton then return end
    minimapButton:ClearAllPoints()
    if Minimap then
        local width, height = Minimap:GetWidth(), Minimap:GetHeight()
        if not number(width) or not number(height) then return end
        local radians = math.rad(angle or ns.db.minimapAngle)
        minimapButton:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(radians) * (width / 2 + 5), math.sin(radians) * (height / 2 + 5))
    else
        minimapButton:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -24, -90)
    end
end

local function dragButton(self)
    if not Minimap then return end
    local x, y = GetCursorPosition()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    if not number(x) or not number(y) or not number(mx) or not number(my)
        or not number(scale) or scale <= 0 then return end
    self.angle = math.deg(math.atan2(y / scale - my, x / scale - mx)) % 360
    positionButton(self.angle)
end

local function stopDragging(self)
    if not self.dragging then return end
    self.dragging = nil
    self:SetScript("OnUpdate", nil)
    if self.angle then ns:SetOption("minimapAngle", self.angle) end
    self.angle = nil
end

local function createMinimapButton()
    local button = CreateFrame("Button", "SimpleSellPriceMinimapButton", Minimap or UIParent)
    minimapButton = button
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(25, 25)
    background:SetPoint("CENTER")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\SimpleSellPrice\\Media\\Icon")
    icon:SetSize(19, 19)
    icon:SetPoint("CENTER")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    button:SetScript("OnMouseDown", function(self) self.dragged = nil end)
    button:SetScript("OnDragStart", function(self)
        if not Minimap then return end
        self.dragging, self.dragged = true, true
        hideTooltip(self)
        self:SetScript("OnUpdate", dragButton)
        dragButton(self)
    end)
    button:SetScript("OnDragStop", stopDragging)
    button:SetScript("OnClick", function(self)
        -- Some clients emit a click after OnDragStop. Keep the flag until
        -- the next mouse-down so repositioning never toggles the window.
        if not self.dragged and not self.dragging then ns:ToggleSettings() end
    end)
    button:SetScript("OnEnter", function(self)
        if self.dragging or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Simple Sell Price")
        GameTooltip:AddLine("v" .. ns.VERSION .. " by " .. ns.AUTHOR, 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Click for settings. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", hideTooltip)
    button:SetScript("OnHide", function(self)
        stopDragging(self)
        hideTooltip(self)
    end)
    button:RegisterEvent("UI_SCALE_CHANGED")
    button:RegisterEvent("DISPLAY_SIZE_CHANGED")
    button:SetScript("OnEvent", function() positionButton() end)
    if Minimap then
        Minimap:HookScript("OnSizeChanged", function() positionButton() end)
    end
end

local function checkbox(parent, key, label, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", 16, y)
    check.Text:SetFontObject("GameFontHighlight")
    check.Text:SetText(label)
    check:SetHitRectInsets(0, -260, 0, 0)
    check:SetScript("OnClick", function(self) ns:SetOption(key, self:GetChecked() == true) end)
    return check
end

local function createWindow()
    window = CreateFrame("Frame", "SimpleSellPriceSettings", UIParent, "BasicFrameTemplateWithInset")
    window:Hide()
    window:SetSize(330, 202)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window.TitleText:SetText("Simple Sell Price")
    table.insert(UISpecialFrames, "SimpleSellPriceSettings")

    local title = CreateFrame("Frame", nil, window)
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", -36, 0)
    title:SetHeight(24)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() window:StartMoving() end)
    title:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
    window:SetScript("OnHide", function() window:StopMovingOrSizing() end)

    local help = window:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", 22, -42)
    help:SetWidth(286)
    help:SetJustifyH("LEFT")
    help:SetText("Unit sell price by default.\nHold Shift for the whole stack.")

    window.showBoth = checkbox(window, "showBoth", "Show unit and stack prices together", -88)
    window.showMinimap = checkbox(window, "showMinimap", "Show minimap button", -122)

    local hint = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 22, 16)
    hint:SetText("/ssp for settings")
    local credit = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    credit:SetPoint("BOTTOMRIGHT", -22, 16)
    credit:SetText(ns.AUTHOR .. "  |  v" .. ns.VERSION)
    window:SetScript("OnShow", function() ns:RefreshUI() end)
end

function ns:RefreshUI()
    if not self.db then return end
    if window then
        window.showBoth:SetChecked(self.db.showBoth)
        window.showMinimap:SetChecked(self.db.showMinimap)
    end
    if minimapButton then
        if not minimapButton.dragging then positionButton() end
        minimapButton:SetShown(self.db.showMinimap)
    end
end

function ns:InitializeUI()
    if window then return end
    createWindow()
    createMinimapButton()
    self:RefreshUI()
end

function ns:ToggleSettings()
    if not self.db then return end
    if not window then self:InitializeUI() end
    window:SetShown(not window:IsShown())
end
