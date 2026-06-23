local WIKI_URL = "https://www.yuque.com/wortox-2sulw/wuga1v/ttgpzxp2seaw7nga"
local RULES_URL = "https://www.yuque.com/wortox-2sulw/wuga1v/wxk8b6g9v86gaodq?singleDoc#"
local WIKI_BUTTON_TEXT = string.char(230, 184, 184, 230, 136, 143, 231, 153, 190, 231, 167, 145)
local RULES_BUTTON_TEXT = string.char(230, 184, 184, 230, 136, 143, 232, 167, 132, 229, 136, 153) -- 游戏规则
local LOBBY_LINK_BUTTON_SIZE = {140, 45}
local LOBBY_LINK_BUTTON_GAP = 10
local LOBBY_WIKI_BUTTON_X = 520
local LOBBY_WIKI_BUTTON_Y = 310
local TEXT_YES = string.char(230, 152, 175)
local TEXT_NO = string.char(229, 144, 166)
local LOBBY_TOGGLE_DEBOUNCE = 0.35
local RANDOM_GHOST_COMMAND = "nightmarerandomghosts"
local RANDOM_GHOST_BUTTON_TEXT = string.char(233, 154, 143, 230, 156, 186, 233, 172, 188)
local RANDOM_GHOST_TITLE = string.char(233, 172, 188, 231, 154, 132, 228, 184, 170, 230, 149, 176)
local RANDOM_GHOST_BODY = "Number"
local RANDOM_GHOST_OK = "OK"
local RANDOM_GHOST_CANCEL = "Cancel"
local RANDOM_GHOST_RESULT_PREFIX = string.char(230, 156, 172, 232, 189, 174, 230, 184, 184, 230, 136, 143, 233, 154, 143, 230, 156, 186, 231, 154, 132, 233, 172, 188, 228, 184, 186, 239, 188, 154)
local RANDOM_GHOST_SEPARATOR = string.char(239, 188, 140)
local SHOW_EXTRA_BUTTONS_TEXT = string.char(230, 152, 190, 231, 164, 186, 233, 162, 157, 229, 164, 150, 230, 140, 137, 233, 146, 174)
local HIDE_EXTRA_BUTTONS_TEXT = string.char(233, 154, 144, 232, 151, 143, 233, 162, 157, 229, 164, 150, 230, 140, 137, 233, 146, 174)

local SUPPLY_OPTIONS = {
    {
        id = "imp",
        default_enabled = true,
        label = string.char(229, 176, 143, 230, 129, 182, 233, 173, 148, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "imp_supplies_enabled",
        debounce_key = "last_imp_supplies_toggle_time",
        command = "nightmaretoggleimpsupplies",
        netvar = "_nightmare_imp_supplies_enabled",
        netname = "nightmare_lobby_changes._imp_supplies_enabled",
        dirty = "nightmare_imp_supplies_dirty",
        y = 260,
    },
    {
        id = "willow",
        default_enabled = true,
        label = string.char(231, 129, 171, 229, 165, 179, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "willow_supplies_enabled",
        debounce_key = "last_willow_supplies_toggle_time",
        command = "nightmaretogglewillowsupplies",
        netvar = "_nightmare_willow_supplies_enabled",
        netname = "nightmare_lobby_changes._willow_supplies_enabled",
        dirty = "nightmare_willow_supplies_dirty",
        y = 210,
    },
    {
        id = "wigfrid",
        default_enabled = true,
        label = string.char(229, 165, 179, 230, 173, 166, 231, 165, 158, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wigfrid_supplies_enabled",
        debounce_key = "last_wigfrid_supplies_toggle_time",
        command = "nightmaretogglewigfridsupplies",
        netvar = "_nightmare_wigfrid_supplies_enabled",
        netname = "nightmare_lobby_changes._wigfrid_supplies_enabled",
        dirty = "nightmare_wigfrid_supplies_dirty",
        y = 160,
    },
    {
        id = "woodie",
        default_enabled = false,
        label = string.char(228, 188, 141, 232, 191, 170, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "woodie_supplies_enabled",
        debounce_key = "last_woodie_supplies_toggle_time",
        command = "nightmaretogglewoodiesupplies",
        netvar = "_nightmare_woodie_supplies_enabled",
        netname = "nightmare_lobby_changes._woodie_supplies_enabled",
        dirty = "nightmare_woodie_supplies_dirty",
        y = 110,
    },
    {
        id = "wanda",
        default_enabled = false,
        label = string.char(230, 151, 186, 232, 190, 190, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wanda_supplies_enabled",
        debounce_key = "last_wanda_supplies_toggle_time",
        command = "nightmaretogglewandasupplies",
        netvar = "_nightmare_wanda_supplies_enabled",
        netname = "nightmare_lobby_changes._wanda_supplies_enabled",
        dirty = "nightmare_wanda_supplies_dirty",
        y = 60,
    },
    {
        id = "wolfgang",
        default_enabled = false,
        label = string.char(230, 178, 131, 229, 176, 148, 229, 164, 171, 229, 134, 136, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wolfgang_supplies_enabled",
        debounce_key = "last_wolfgang_supplies_toggle_time",
        command = "nightmaretogglewolfgangsupplies",
        netvar = "_nightmare_wolfgang_supplies_enabled",
        netname = "nightmare_lobby_changes._wolfgang_supplies_enabled",
        dirty = "nightmare_wolfgang_supplies_dirty",
        y = 10,
    },
    {
        id = "wendy",
        default_enabled = false,
        label = string.char(230, 184, 169, 232, 146, 171, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wendy_supplies_enabled",
        debounce_key = "last_wendy_supplies_toggle_time",
        command = "nightmaretogglewendysupplies",
        netvar = "_nightmare_wendy_supplies_enabled",
        netname = "nightmare_lobby_changes._wendy_supplies_enabled",
        dirty = "nightmare_wendy_supplies_dirty",
        y = -40,
    },
    {
        id = "wickerbottom",
        default_enabled = false,
        label = string.char(232, 150, 135, 229, 133, 139, 229, 183, 180, 233, 161, 191, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wickerbottom_supplies_enabled",
        debounce_key = "last_wickerbottom_supplies_toggle_time",
        command = "nightmaretogglewickerbottomsupplies",
        netvar = "_nightmare_wickerbottom_supplies_enabled",
        netname = "nightmare_lobby_changes._wickerbottom_supplies_enabled",
        dirty = "nightmare_wickerbottom_supplies_dirty",
        y = -90,
    },
    {
        id = "wormwood",
        default_enabled = false,
        label = string.char(230, 178, 131, 229, 167, 134, 228, 188, 141, 229, 190, 183, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wormwood_supplies_enabled",
        debounce_key = "last_wormwood_supplies_toggle_time",
        command = "nightmaretogglewormwoodsupplies",
        netvar = "_nightmare_wormwood_supplies_enabled",
        netname = "nightmare_lobby_changes._wormwood_supplies_enabled",
        dirty = "nightmare_wormwood_supplies_dirty",
        y = -140,
    },
    {
        id = "wx78",
        default_enabled = false,
        label = string.char(87, 88, 45, 55, 56, 229, 136, 157, 229, 167, 139, 231, 137, 169, 232, 181, 132, 239, 188, 154),
        state_key = "wx78_supplies_enabled",
        debounce_key = "last_wx78_supplies_toggle_time",
        command = "nightmaretogglewx78supplies",
        netvar = "_nightmare_wx78_supplies_enabled",
        netname = "nightmare_lobby_changes._wx78_supplies_enabled",
        dirty = "nightmare_wx78_supplies_dirty",
        y = -190,
    },
}

local lobby_options = rawget(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS")
if lobby_options == nil then
    lobby_options = {}
    rawset(GLOBAL, "NIGHTMARE_LOBBY_OPTIONS", lobby_options)
end

for _, option in ipairs(SUPPLY_OPTIONS) do
    if lobby_options[option.state_key] == nil then
        lobby_options[option.state_key] = option.default_enabled == true
    end
    lobby_options[option.debounce_key] = lobby_options[option.debounce_key] or -999
end

local function GetSupplyState(option)
    return lobby_options[option.state_key] == true
end

local function SetSupplyState(option, enabled)
    lobby_options[option.state_key] = enabled == true
    return lobby_options[option.state_key]
end

local function PublishSupplyState(option)
    if TheWorld ~= nil and TheWorld.net ~= nil and TheWorld.net[option.netvar] ~= nil then
        TheWorld.net[option.netvar]:set(GetSupplyState(option))
    end
end

-- 大厅里房主 caller.admin 常为 nil；COMMAND_PERMISSION.ADMIN 也会因此直接拒令
local function IsCallerAdmin(caller)
    if caller == nil then
        return false
    end
    if caller.admin == true then
        return true
    end
    local userid = caller.userid
    if userid == nil or userid == "" then
        return false
    end
    if TheNet.GetIsUserAdmin ~= nil and TheNet:GetIsUserAdmin(userid) then
        return true
    end
    local data = TheNet:GetClientTableForUser(userid)
    if data ~= nil and data.admin == true then
        return true
    end
    -- 联机房主（listen server）
    if userid == TheNet:GetUserID() then
        if TheNet.GetIsServerOwner ~= nil and TheNet:GetIsServerOwner() then
            return true
        end
        if TheNet.GetIsServerAdmin ~= nil and TheNet:GetIsServerAdmin() then
            return true
        end
    end
    return false
end

local function ToggleSupplyState(option, caller)
    if not IsCallerAdmin(caller) then
        return
    end
    local now = GetTimeRealSeconds()
    if now - lobby_options[option.debounce_key] >= LOBBY_TOGGLE_DEBOUNCE then
        lobby_options[option.debounce_key] = now
        SetSupplyState(option, not GetSupplyState(option))
        PublishSupplyState(option)
    end
end

local function SendLobbySystemMessage(message)
    if TheNet ~= nil and TheNet.SystemMessage ~= nil then
        TheNet:SystemMessage(message)
    else
        print("[NIGHTMARE_LOBBY]", message)
    end
end

local function GetRandomGhostPlayers()
    local players = {}
    local clients = TheNet ~= nil and TheNet:GetClientTable() or nil

    for _, client in ipairs(clients or {}) do
        local userid = client ~= nil and client.userid or nil
        if userid ~= nil and userid ~= "" then
            table.insert(players, {
                userid = userid,
                name = client.name ~= nil and client.name ~= "" and client.name or userid,
            })
        end
    end

    return players
end

local function PickRandomGhostNames(count)
    local pool = GetRandomGhostPlayers()
    local selected = {}

    for i = 1, count do
        if #pool <= 0 then
            break
        end
        local index = math.random(#pool)
        table.insert(selected, pool[index].name)
        table.remove(pool, index)
    end

    return selected
end

local function RunRandomGhostSelection(params, caller)
    local count = tonumber(params ~= nil and params.count or nil)
    if count == nil or math.floor(count) ~= count then
        SendLobbySystemMessage("random ghost Number must be an integer")
        return
    end
    if count <= 0 then
        SendLobbySystemMessage("random ghost Number must be greater than 0")
        return
    end

    local player_count = #GetRandomGhostPlayers()
    if player_count <= 0 then
        SendLobbySystemMessage("random ghost failed: no players")
        return
    end
    if count > player_count then
        SendLobbySystemMessage("random ghost Number is greater than current players: " .. tostring(player_count))
        return
    end

    SendLobbySystemMessage(RANDOM_GHOST_RESULT_PREFIX .. table.concat(PickRandomGhostNames(count), RANDOM_GHOST_SEPARATOR))
end

AddPrefabPostInit("forest_network", function(inst)
    for _, option in ipairs(SUPPLY_OPTIONS) do
        if inst[option.netvar] == nil then
            inst[option.netvar] = net_bool(inst.GUID, option.netname, option.dirty)
        end

        if TheWorld ~= nil and TheWorld.ismastersim then
            inst[option.netvar]:set(GetSupplyState(option))
        end
    end
end)

AddUserCommand(RANDOM_GHOST_COMMAND, {
    prettyname = nil,
    desc = nil,
    permission = COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = { "count" },
    vote = false,
    canstartfn = function(command, caller, targetid)
        return true
    end,
    serverfn = function(params, caller)
        RunRandomGhostSelection(params, caller)
    end,
})

for _, option_def in ipairs(SUPPLY_OPTIONS) do
    local option = option_def
    AddUserCommand(option.command, {
        prettyname = nil,
        desc = nil,
        permission = COMMAND_PERMISSION.USER,
        slash = false,
        usermenu = false,
        servermenu = false,
        params = {},
        vote = false,
        canstartfn = function(command, caller, targetid)
            return IsCallerAdmin(caller)
        end,
        serverfn = function(params, caller)
            ToggleSupplyState(option, caller)
        end,
    })
end

if TheNet ~= nil and TheNet:IsDedicated() then
    return
end

local TEMPLATES = require "widgets/redux/templates"
local UserCommands = require "usercommands"
local InputDialogScreen = require "screens/redux/inputdialog"
local active_lobby_screen = nil

local function IsLobbyAdmin()
    return TheNet ~= nil and (TheNet:GetIsServerAdmin() or TheNet:GetIsServerOwner())
end

local function GetSupplyButtonText(option, enabled)
    return option.label .. (enabled and TEXT_YES or TEXT_NO)
end

local function OpenWikiLink()
    VisitURL(WIKI_URL, true)
end

local function OpenRulesLink()
    VisitURL(RULES_URL, true)
end

local function ConfigureLobbyLinkButton(button)
    if NEWFONT ~= nil then
        button:SetFont(NEWFONT)
        button:SetDisabledFont(NEWFONT)
    end
    button:SetTextSize(20)
end

local function SendRandomGhostRequest(count)
    UserCommands.RunUserCommand(RANDOM_GHOST_COMMAND, { count = tostring(count or "") }, TheNet:GetClientTableForUser(TheNet:GetUserID()))
end

local function OpenRandomGhostDialog()
    local dialog = nil
    dialog = InputDialogScreen(RANDOM_GHOST_TITLE, {
        {
            text = RANDOM_GHOST_OK,
            cb = function()
                TheFrontEnd:PopScreen()
                SendRandomGhostRequest(dialog ~= nil and dialog:GetActualString() or "")
            end,
        },
        {
            text = RANDOM_GHOST_CANCEL,
            cb = function()
                TheFrontEnd:PopScreen()
            end,
        },
    }, true)
    dialog:SetValidChars("-0123456789")
    dialog:OverrideText("1")
    dialog.edit_text.OnTextEntered = function()
        TheFrontEnd:PopScreen()
        SendRandomGhostRequest(dialog:GetActualString())
    end

    TheFrontEnd:PushScreen(dialog)
    dialog.edit_text:SetForceEdit(true)
    dialog.edit_text:OnControl(CONTROL_ACCEPT, false)
end

local function GetNetworkSupplyState(option)
    return TheWorld ~= nil
        and TheWorld.net ~= nil
        and TheWorld.net[option.netvar] ~= nil
        and TheWorld.net[option.netvar]:value() == true
end

local function SetLocalSupplyState(screen, option, enabled)
    local state_field = "_nightmare_" .. option.id .. "_supplies_enabled"
    local button_field = "_nightmare_" .. option.id .. "_supplies_button"

    screen[state_field] = enabled == true
    if screen[button_field] ~= nil then
        screen[button_field]:SetText(GetSupplyButtonText(option, screen[state_field]))
    end
end

local function RefreshSupplyButton(option)
    if active_lobby_screen ~= nil then
        SetLocalSupplyState(active_lobby_screen, option, GetNetworkSupplyState(option))
    end
end

local function RefreshAllSupplyButtons(screen)
    for _, option in ipairs(SUPPLY_OPTIONS) do
        SetLocalSupplyState(screen, option, GetNetworkSupplyState(option))
    end
end

local function ApplyExtraButtonsVisibility(screen)
    local visible = screen._nightmare_extra_buttons_visible == true
    local buttons = {
        screen._nightmare_wiki_button,
        screen._nightmare_rules_button,
        screen._nightmare_random_ghost_button,
    }

    for _, option in ipairs(SUPPLY_OPTIONS) do
        table.insert(buttons, screen["_nightmare_" .. option.id .. "_supplies_button"])
    end

    for _, button in ipairs(buttons) do
        if button ~= nil then
            if visible then
                button:Show()
            else
                button:Hide()
            end
        end
    end

    if screen._nightmare_extra_buttons_toggle ~= nil then
        screen._nightmare_extra_buttons_toggle:SetText(visible and HIDE_EXTRA_BUTTONS_TEXT or SHOW_EXTRA_BUTTONS_TEXT)
    end
end

local function ToggleExtraButtonsVisibility(screen)
    screen._nightmare_extra_buttons_visible = screen._nightmare_extra_buttons_visible ~= true
    if screen._nightmare_extra_buttons_visible then
        RefreshAllSupplyButtons(screen)
    end
    ApplyExtraButtonsVisibility(screen)
end

local function AddSupplyButton(screen, option)
    local state_field = "_nightmare_" .. option.id .. "_supplies_enabled"
    local button_field = "_nightmare_" .. option.id .. "_supplies_button"
    local timeout_field = "_nightmare_" .. option.id .. "_supplies_timeout_task"

    screen[state_field] = GetNetworkSupplyState(option)
    screen[button_field] = screen.root:AddChild(TEMPLATES.StandardButton(function()
        if screen[button_field] ~= nil then
            screen[button_field]:Disable()
        end
        UserCommands.RunUserCommand(option.command, {}, TheNet:GetClientTableForUser(TheNet:GetUserID()))
        screen[timeout_field] = screen.inst:DoTaskInTime(2, function()
            RefreshSupplyButton(option)
        end)
    end, GetSupplyButtonText(option, screen[state_field]), {220, 45}))
    screen[button_field]:SetPosition(490, option.y)
    screen[button_field]:SetTextSize(22)

    if TheWorld ~= nil and TheWorld.net ~= nil then
        screen.inst:ListenForEvent(option.dirty, function()
            if screen[timeout_field] ~= nil then
                screen[timeout_field]:Cancel()
                screen[timeout_field] = nil
            end
            RefreshSupplyButton(option)
        end, TheWorld.net)
    end
end

local function CancelSupplyButtonTasks(screen)
    for _, option in ipairs(SUPPLY_OPTIONS) do
        local timeout_field = "_nightmare_" .. option.id .. "_supplies_timeout_task"
        if screen[timeout_field] ~= nil then
            screen[timeout_field]:Cancel()
            screen[timeout_field] = nil
        end
    end
end

local function AddLobbyButtons(self)
    if self.root == nil or self._nightmare_wiki_button ~= nil then
        return
    end

    active_lobby_screen = self

    local rules_x = LOBBY_WIKI_BUTTON_X - LOBBY_LINK_BUTTON_SIZE[1] - LOBBY_LINK_BUTTON_GAP

    self._nightmare_rules_button = self.root:AddChild(TEMPLATES.StandardButton(OpenRulesLink, RULES_BUTTON_TEXT, LOBBY_LINK_BUTTON_SIZE))
    self._nightmare_rules_button:SetPosition(rules_x, LOBBY_WIKI_BUTTON_Y)
    ConfigureLobbyLinkButton(self._nightmare_rules_button)

    self._nightmare_wiki_button = self.root:AddChild(TEMPLATES.StandardButton(OpenWikiLink, WIKI_BUTTON_TEXT, LOBBY_LINK_BUTTON_SIZE))
    self._nightmare_wiki_button:SetPosition(LOBBY_WIKI_BUTTON_X, LOBBY_WIKI_BUTTON_Y)
    ConfigureLobbyLinkButton(self._nightmare_wiki_button)

    self._nightmare_random_ghost_button = self.root:AddChild(TEMPLATES.StandardButton(function()
        OpenRandomGhostDialog()
    end, RANDOM_GHOST_BUTTON_TEXT, {160, 45}))
    self._nightmare_random_ghost_button:SetPosition(520, -250)
    self._nightmare_random_ghost_button:SetTextSize(22)

    if IsLobbyAdmin() then
        for _, option in ipairs(SUPPLY_OPTIONS) do
            AddSupplyButton(self, option)
        end

        self._nightmare_extra_buttons_visible = true
        self._nightmare_extra_buttons_toggle = self.root:AddChild(TEMPLATES.StandardButton(function()
            ToggleExtraButtonsVisibility(self)
        end, HIDE_EXTRA_BUTTONS_TEXT, {160, 45}))
        self._nightmare_extra_buttons_toggle:SetPosition(-50, -310)
        self._nightmare_extra_buttons_toggle:SetTextSize(22)
        ApplyExtraButtonsVisibility(self)
    end

    if self.inst ~= nil then
        self.inst:ListenForEvent("onremove", function()
            CancelSupplyButtonTasks(self)
            if active_lobby_screen == self then
                active_lobby_screen = nil
            end
        end)
    end
end

AddClassPostConstruct("screens/redux/lobbyscreen", AddLobbyButtons)
