-- 韦伯专用：游戏内骰子/召唤 HUD 按钮（与 Shift+T/Y/U 等效）

if TheNet ~= nil and TheNet:IsDedicated() then
    return
end

local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

local BUTTON_W = 100
local BUTTON_GAP = 6

local MONSTER_POOL_BUTTON_TEXT = string.char(230, 128, 170, 231, 137, 169, 230, 177, 160) -- 怪物池
local CONTROL_POOL_BUTTON_TEXT = string.char(230, 142, 167, 229, 136, 182, 230, 177, 160) -- 控制池
local BOSS_POOL_BUTTON_TEXT = "Boss" .. string.char(230, 177, 160) -- Boss池

local function GetLocalPlayer()
    return ThePlayer
end

local function IsWebberPlayer()
    local player = GetLocalPlayer()
    return player ~= nil and player:IsValid() and player.prefab == "webber"
end

local function CanUseDiceButton()
    local owner = GetLocalPlayer()
    if owner == nil or not owner:IsValid() then
        return false
    end
    local pc = owner.components and owner.components.playercontroller or nil
    if pc == nil then
        return true
    end
    local enabled, hudblocking = pc:IsEnabled()
    return enabled or hudblocking
end

local function ConfigureButton(button)
    button.image:SetScale(1.05, 1.05)
    button:SetFont(BUTTONFONT)
    button:SetDisabledFont(BUTTONFONT)
    button:SetTextSize(22)
    button.text:SetVAlign(ANCHOR_MIDDLE)
    button.text:SetColour(0, 0, 0, 1)
end

local RogeDiceButtons = Class(Widget, function(self, controls, button_defs)
    Widget._ctor(self, "roge_dice_buttons")
    self.controls = controls
    self.buttons = {}
    self:SetClickable(true)

    for i, def in ipairs(button_defs or {}) do
        local fn = def.fn
        local btn = self:AddChild(ImageButton(
            "images/ui.xml",
            "button_small.tex",
            "button_small_over.tex",
            "button_small_disabled.tex",
            nil, nil, { 1, 1 }, { 0, 0 }
        ))
        btn:SetPosition(-(BUTTON_W * 0.5 + (i - 1) * (BUTTON_W + BUTTON_GAP)), 0)
        btn:SetText(def.text or "")
        ConfigureButton(btn)
        if def.hover ~= nil then
            btn:SetHoverText(def.hover)
        end
        btn:SetOnClick(function()
            if not CanUseDiceButton() then
                return
            end
            if fn ~= nil then
                fn()
            end
        end)
        self.buttons[#self.buttons + 1] = btn
    end

    self:RefreshVisibility()
end)

function RogeDiceButtons:RefreshVisibility()
    if IsWebberPlayer() then
        self:Show()
    else
        self:Hide()
    end
end

local function BuildButtonDefs()
    return {
        {
            text = MONSTER_POOL_BUTTON_TEXT,
            hover = "Shift+T",
            fn = RogeTryShiftTDiceRoll,
        },
        {
            text = CONTROL_POOL_BUTTON_TEXT,
            hover = "Shift+Y",
            fn = RogeTryShiftYSummon,
        },
        {
            text = BOSS_POOL_BUTTON_TEXT,
            hover = "Shift+U",
            fn = RogeTryShiftUSummon,
        },
    }
end

local function AttachRogeDiceButtons(controls)
    if controls == nil or controls.roge_dice_buttons ~= nil then
        return false
    end

    local parent = controls.bottomright_root or controls.topright_over_root or controls.topright_root
    if parent == nil then
        return false
    end

    local ok, widget_or_err = pcall(function()
        return parent:AddChild(RogeDiceButtons(controls, BuildButtonDefs()))
    end)
    if not ok or widget_or_err == nil then
        print("[roge] failed to attach dice hud buttons:", widget_or_err)
        return false
    end

    controls.roge_dice_buttons = widget_or_err
    controls.roge_dice_buttons:SetPosition(-340, 110)
    controls.roge_dice_buttons:MoveToFront()
    controls.roge_dice_buttons:RefreshVisibility()
    print("[roge] dice hud attached, player=", ThePlayer ~= nil and ThePlayer.prefab or "nil")
    return true
end

local function RefreshAttachedDiceButtons(controls)
    if controls ~= nil and controls.roge_dice_buttons ~= nil then
        controls.roge_dice_buttons:RefreshVisibility()
    end
end

local function BindDiceButtonEvents(controls)
    if controls == nil or controls._roge_dice_events_bound then
        return
    end
    controls._roge_dice_events_bound = true

    if controls.owner ~= nil then
        controls.inst:ListenForEvent("finishseamlessplayerswap", function()
            RefreshAttachedDiceButtons(controls)
        end, controls.owner)
    end

    if TheWorld ~= nil then
        controls.inst:ListenForEvent("continuefrompause", function()
            RefreshAttachedDiceButtons(controls)
        end, TheWorld)
    end
end

local function PatchControlsGhostMode(controls)
    if controls == nil or controls._roge_ghostmode_patched then
        return
    end
    controls._roge_ghostmode_patched = true
    local OldSetGhostMode = controls.SetGhostMode
    controls.SetGhostMode = function(self, isghost, ...)
        OldSetGhostMode(self, isghost, ...)
        RefreshAttachedDiceButtons(self)
    end
end

local function TryAttachDiceHud(controls)
    if controls == nil then
        return
    end
    PatchControlsGhostMode(controls)
    BindDiceButtonEvents(controls)
    AttachRogeDiceButtons(controls)
end

AddClassPostConstruct("widgets/controls", function(self)
    if self.inst ~= nil then
        self.inst:DoTaskInTime(0, function()
            if self.inst ~= nil and self.inst:IsValid() then
                TryAttachDiceHud(self)
            end
        end)
    else
        TryAttachDiceHud(self)
    end
end)

if not rawget(GLOBAL, "_roge_dice_playerhud_patched") then
    rawset(GLOBAL, "_roge_dice_playerhud_patched", true)

    AddClassPostConstruct("screens/playerhud", function(PlayerHud)
        local OldSetMainCharacter = PlayerHud.SetMainCharacter
        function PlayerHud:SetMainCharacter(maincharacter, ...)
            local ret = OldSetMainCharacter(self, maincharacter, ...)
            if self.controls ~= nil then
                TryAttachDiceHud(self.controls)
            end
            return ret
        end
    end)
end
