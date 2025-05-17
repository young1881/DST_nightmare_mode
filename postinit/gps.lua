local ENABLEPINGS = true --GetModConfigData("ENABLEPINGS")
if ENABLEPINGS then --Only request loading of ping assets if pings are enabled
	table.insert(PrefabFiles, "pings")
	for _,ping in ipairs({"generic", "gohere", "explore", "danger", "omw"}) do
		table.insert(Assets, Asset("IMAGE", "minimap/ping_"..ping..".tex"))
		table.insert(Assets, Asset("ATLAS", "minimap/ping_"..ping..".xml"))
		AddMinimapAtlas("minimap/ping_"..ping..".xml")
	end
	for _,action in ipairs({"", "Danger", "Explore", "GoHere", "Omw", "Cancel", "Delete", "Clear"}) do
		table.insert(Assets, Asset("IMAGE", "images/Ping"..action..".tex"))
		table.insert(Assets, Asset("ATLAS", "images/Ping"..action..".xml"))
	end
end

AddPrefabPostInit("forest_network", function(inst) inst:AddComponent("globalpositions") end)
AddPrefabPostInit("cave_network", function(inst) inst:AddComponent("globalpositions") end)


-- This is for the target indicator images; map icons inherit directly from the prefab
local TARGET_INDICATOR_ICONS = {
	-- atlas is left nil if the image is in inventoryimages
	-- image is left nil if the image is just the key.tex
	-- for example, setting both fields for campfire to nil results in these values:
	-- campfire = {atlas = "images/inventoryimages.xml", image = "campfire.tex"}
	ping_generic = {atlas = "images/Ping.xml", image = "Ping.tex"},
	ping_danger = {atlas = "images/PingDanger.xml", image = "PingDanger.tex"},
	ping_omw = {atlas = "images/PingOmw.xml", image = "PingOmw.tex"},
	ping_explore = {atlas = "images/PingExplore.xml", image = "PingExplore.tex"},
	ping_gohere = {atlas = "images/PingGoHere.xml", image = "PingGoHere.tex"},
}

-- Expose this so that other mods can add data for things they want to have icons/indicators for

GLOBAL._GLOBALPOSITIONS_TARGET_INDICATOR_ICONS = TARGET_INDICATOR_ICONS
local lang=GetModConfigData("language")
if lang=="default" then
	lang=GLOBAL.LOC.CurrentLocale and GLOBAL.LOC.CurrentLocale.code or GLOBAL.LanguageTranslator.defaultlang
end
if lang=="" then
	lang="en"
end
if ENABLEPINGS then
	GLOBAL.STRINGS.NAMES.PING_GENERIC = "Point of Interest"
	GLOBAL.STRINGS.NAMES.PING_DANGER = "Danger"
	GLOBAL.STRINGS.NAMES.PING_OMW = "On My Way"
	GLOBAL.STRINGS.NAMES.PING_EXPLORE = "Explore Here"
	GLOBAL.STRINGS.NAMES.PING_GOHERE = "Go Here"
	if lang=="zh" or lang=="zht" or lang=="zhr" then
		GLOBAL.STRINGS.NAMES.PING_GENERIC = "集合"
		GLOBAL.STRINGS.NAMES.PING_DANGER = "危险"
		GLOBAL.STRINGS.NAMES.PING_OMW = "必由之路"
		GLOBAL.STRINGS.NAMES.PING_EXPLORE = "探图"
		GLOBAL.STRINGS.NAMES.PING_GOHERE = "去这里"
	end
end

AddClassPostConstruct("screens/playerhud", function(PlayerHud)
	if true then return end
	PlayerHud.targetindicators = {}
	local mastersim = GLOBAL.TheNet:GetIsServer()
	local OldSetMainCharacter = PlayerHud.SetMainCharacter
	function PlayerHud:SetMainCharacter(...)
		local ret = OldSetMainCharacter(self, ...)
		local client_table = GLOBAL.TheNet:GetClientTable() or {}
		for k,v in pairs(GLOBAL.TheWorld.net.components.globalpositions.positions) do
			if v.userid:value() == "nil" and TARGET_INDICATOR_ICONS[v.parentprefab:value()] then
				self:AddTargetIndicator(v)
				self.targetindicators[#self.targetindicators]:Hide()
				v:UpdatePortrait()
			end
			--for each global position already added to the table...
			--[[
			if SHOWPLAYERINDICATORS then
				for j,w in pairs(client_table) do
					if v.userid:value() == w.userid -- find the corresponding player...
					and w.userid ~= self.owner.userid then -- but not the local player...
						v.playercolor = w.colour
						v.name = w.name
						self:AddTargetIndicator(v)
						self.targetindicators[#self.targetindicators]:Hide()
						v:UpdatePortrait()
					end
				end
			end
			]]
		end
		return ret
	end

	--Basically the following two functions cause it to find the matching globalposition_classified's
	-- indicator, and tell it to be hidden while the normal indicator is up.
	local OldAddTargetIndicator = PlayerHud.AddTargetIndicator
	function PlayerHud:AddTargetIndicator(target)
		if type(target.userid) ~= "userdata" then --this is a normal player target indicator
			for k,v in pairs(self.targetindicators) do
				if type(v.target.userid) == "userdata" and v.target.userid:value() == target.userid then
					-- this is a target indicator for the same player's globalposition_classified
					v.hidewhileclose = true
				end
			end
		end
		OldAddTargetIndicator(self, target)
	end
	local OldRemoveTargetIndicator = PlayerHud.RemoveTargetIndicator
	function PlayerHud:RemoveTargetIndicator(target)
		if type(target.userid) ~= "userdata" then --this is a normal player target indicator
			for k,v in pairs(self.targetindicators) do
				if type(v.target.userid) == "userdata" and v.target.userid:value() == target.userid then
					-- this is a target indicator for the same player's globalposition_classified
					v.hidewhileclose = false
				end
			end
		end
		OldRemoveTargetIndicator(self, target)
	end

	local OldOnUpdate = PlayerHud.OnUpdate
	function PlayerHud:OnUpdate(...)
		local ret = OldOnUpdate(self, ...)
		local onscreen = {}
		if self.owner and self.owner.components and self.owner.components.playertargetindicator then
			onscreen = self.owner.components.playertargetindicator.onScreenPlayersLastTick
		end
		if self.targetindicators then
			for j,w in pairs(self.targetindicators) do --for each target indicator...
				local show = true
				if type(w.target.userid) == "userdata" then --if it's a globalposition_classified...
					-- globalpositions should only be shown on the scoreboard screen
					-- or if the show always option is set
					-- but we also don't want to have it showing when the normal indicator is,
					-- because that produces awful flickering
					show = false --SHOWPLAYERSALWAYS and (not w.hidewhileclose) or self:IsStatusScreenOpen()
					--[[
					if not w.is_character then
						local parent_entity = w.target.parententity:value()
						show = not (parent_entity and parent_entity.entity:FrustumCheck())
						if w.onlyshowonscoreboard then
							show = show and self:IsStatusScreenOpen()
						end
					end
					for k,v in pairs(onscreen) do --check if its userid matches an onscreen player...
						if w.target.userid:value() == v.userid then
							show = false
						end
					end
					]]
					if w.is_character then
						if self:IsStatusScreenOpen() then
							w.name_label:Show()
						elseif not w.focus then
							w.name_label:Hide()
						end
					end
					if GLOBAL.TheFrontEnd.mutedPlayers[w.target.parentuserid:value()] then
						show = false -- for pings from muted players
					end
				elseif mastersim then
					w:Hide()
				end
				if show then
					w:Show()
				else
					w:Hide()
				end
			end
		end
		return ret
	end

	local OldShowPlayerStatusScreen = PlayerHud.ShowPlayerStatusScreen
	function PlayerHud:ShowPlayerStatusScreen(...)
		local ret = OldShowPlayerStatusScreen(self, ...)
		self:OnUpdate(0.0001)
		return ret
	end
end)

--[[ Patch TheFrontEnd to track changes in muted players ]]--
require("frontend")
local OldFrontEnd_ctor = GLOBAL.FrontEnd._ctor
GLOBAL.FrontEnd._ctor = function(TheFrontEnd, ...)
	OldFrontEnd_ctor(TheFrontEnd, ...)
	-- to prevent the table from getting deleted
	if not TheFrontEnd.mutedPlayers then
		TheFrontEnd.mutedPlayers = {}
	end
	if not TheFrontEnd.mutedPlayers.DontDeleteMePlz then
		TheFrontEnd.mutedPlayers.DontDeleteMePlz = true
	end
end

--[[ Patch the map to allow names to show on hover-over and pings ]]--
local STARTSCALE = 0.25
local NORMSCALE = 1
local pingwheel = nil
local pingwheelup = false
local activepos = nil
local ReceivePing = nil
local ShowPingWheel = nil
local HidePingWheel = nil
local pings = {}
--new:announce
local WillAnnounce=GetModConfigData("announce")=="true"
local AnnounceTextFallback={
	en="%s made a %s ping", zh="%s 创建了一个 %s 标记"
}
local AnnounceText=GetModConfigData("announce_format") or AnnounceTextFallback[lang] or AnnounceTextFallback.en
local TextMapping={
	generic="PING_GENERIC",
	danger="PING_DANGER",
	omw="PING_OMW",
	explore="PING_EXPLORE",
	gohere="PING_GOHERE",
}
if ENABLEPINGS then
	ReceivePing = function(player, pingtype, x, y, z)
        -- @Antonio32A 20231108 edit: add type check
		print("ReceivePing", player.userid or player.name or player, pingtype, x, y, z)
		if type(pingtype)~="string" or type(x)~="number" or type(y)~="number" or type(z)~="number" then return end
		if pingtype == "delete" then
			--Find the nearest ping and delete it (if it was actually somewhat close)
			mindistsq, minping = math.huge, nil
			for _,ping in pairs(pings) do
				local px, py, pz = ping.Transform:GetWorldPosition()
				dq = GLOBAL.distsq(x, z, px, pz)
				if dq < mindistsq then
					mindistsq = dq
					minping = ping
				end
			end
			-- Check that their mouse is actually somewhat close to it first, ~20
			if mindistsq < 400 then
				pings[minping.GUID] = nil
				minping:Remove()
			end
		elseif pingtype == "clear" then
			for _,ping in pairs(pings) do
				ping:Remove()
			end
		else
			if WillAnnounce then
				GLOBAL.TheNet:Announce(string.format(AnnounceText,player.name or "?",GLOBAL.STRINGS.NAMES[TextMapping[pingtype] or ""] or "???"))
			end
			local ping = GLOBAL.SpawnPrefab("ping_"..pingtype)
			if not ping then return end
			ping.OnRemoveEntity = function(inst) pings[inst.GUID] = nil end
			ping.parentuserid = player.userid
			ping.Transform:SetPosition(x,y,z)
			pings[ping.GUID] = ping
		end
	end
	AddModRPCHandler(modname, "Ping", ReceivePing)

	ShowPingWheel = function(position)
		if pingwheelup then return end
		pingwheelup = true
		SetModHUDFocus("PingWheel", true)

		activepos = position
		if GLOBAL.TheInput:ControllerAttached() then
			local scr_w, scr_h = GLOBAL.TheSim:GetScreenSize()
			pingwheel:SetPosition(scr_w/2, scr_h/2)
		else
			pingwheel:SetPosition(GLOBAL.TheInput:GetScreenPosition():Get())
		end
		pingwheel:Show()
		pingwheel:ScaleTo(STARTSCALE, NORMSCALE, .25)
	end

	HidePingWheel = function(cancel)
		if not pingwheelup or activepos == nil then return end
		pingwheelup = false
		SetModHUDFocus("PingWheel", false)

		pingwheel:Hide()
		pingwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)

		if pingwheel.activegesture and pingwheel.activegesture ~= "cancel" and not cancel then
			--print("send ping", pingwheel.activegesture)
			SendModRPCToServer(MOD_RPC[modname]["Ping"], pingwheel.activegesture, activepos:Get())
		end
		activepos = nil
	end
	GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
		if button == 1000 and not down then
			HidePingWheel()
		end
	end)
end

AddClassPostConstruct("widgets/mapwidget", function(MapWidget)
	MapWidget.offset = GLOBAL.Vector3(0,0,0)
	-- Hoverers get their text from the owner's tooltip; we set the MapWidget to the owner
	MapWidget.nametext = require("widgets/maphoverer")()
	if ENABLEPINGS then
		MapWidget.pingwheel = require("widgets/pingwheel")()
		pingwheel = MapWidget.pingwheel
		pingwheel.radius = pingwheel.radius * 1.1
		pingwheel:Hide()
		pingwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
	end

	function MapWidget:OnUpdate(dt)
		if ENABLEPINGS then
			pingwheel:OnUpdate()
		end
		if not self.shown or pingwheelup then return end

		-- Begin copy-pasted code (small edits to match modmain environment)
		if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_PRIMARY) then
			local pos = GLOBAL.TheInput:GetScreenPosition()
			if self.lastpos then
				local scale = 2/9
				local dx = scale * ( pos.x - self.lastpos.x )
				local dy = scale * ( pos.y - self.lastpos.y )
				self:Offset( dx, dy ) --#rezecib changed this so we can capture offsets
			end

			self.lastpos = pos
		else
			self.lastpos = nil
		end
		-- End copy-pasted code

		--[[if SHOWPLAYERICONS then]]
			local p = self:GetWorldMousePosition()
			--GLOBAL.mm=self
			mindistsq, gpc = math.huge, nil
			for k,v in pairs(GLOBAL.TheWorld.net.components.globalpositions.positions) do
				--if not GLOBAL.TheFrontEnd.mutedPlayers[v.parentuserid:value()] then--v.userid:value() ~= "nil" then -- this is a player's position
					local x, y, z = v.Transform:GetWorldPosition()
					dq = GLOBAL.distsq(p.x, p.z, x, z)
					if dq < mindistsq then
						mindistsq = dq
						gpc = v
					end
				--end
			end
			--[[]]

			-- Check that their mouse is actually somewhat close to them first
			if math.sqrt(mindistsq) < self.minimap:GetZoom()*10 then
				if self.nametext:GetString() ~= gpc.name then
					self.nametext:SetString(gpc.name)
					self.nametext:SetColour(gpc.playercolour)
				end
			else -- nobody is being moused over
				self.nametext:SetString("")
			end
		--end
		--[[]]
	end

	local OldOffset = MapWidget.Offset
	function MapWidget:Offset(dx, dy, ...)
		self.offset.x = self.offset.x + dx
		self.offset.y = self.offset.y + dy
		OldOffset(self, dx, dy, ...)
	end

	local OldOnShow = MapWidget.OnShow
	function MapWidget:OnShow(...)
		self.offset.x = 0
		self.offset.y = 0
		OldOnShow(self, ...)
	end

	local OldOnZoomIn = MapWidget.OnZoomIn
	function MapWidget:OnZoomIn(...)
		local zoom1 = self.minimap:GetZoom()
		OldOnZoomIn(self, ...)
		local zoom2 = self.minimap:GetZoom()
		if self.shown then
			self.offset = self.offset*zoom1/zoom2
		end
	end

	local OldOnZoomOut = MapWidget.OnZoomOut
	function MapWidget:OnZoomOut(...)
		local zoom1 = self.minimap:GetZoom()
		OldOnZoomOut(self, ...)
		local zoom2 = self.minimap:GetZoom()
		if self.shown and zoom1 < 20 then
			self.offset = self.offset*zoom1/zoom2
		end
	end

	function MapWidget:GetWorldMousePosition()
		-- Get the screen size so we can figure out the position of the center
		local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
		-- But also adjust the center to the position of the player
		-- (this makes it so we only have to take into account camera angle once)
		local cx = screenwidth*.5 + self.offset.x*4.5
		local cy = screenheight*.5 + self.offset.y*4.5
		local mx, my = GLOBAL.TheInput:GetScreenPosition():Get()
		if GLOBAL.TheInput:ControllerAttached() then
			mx, my = screenwidth*.5, screenheight*.5
		end
		-- Calculate the offset of the mouse from the center
		local ox = mx - cx
		local oy = my - cy
		-- Calculate the world distance and world angle
		local angle = GLOBAL.TheCamera:GetHeadingTarget()*math.pi/180
		local wd = math.sqrt(ox*ox + oy*oy)*self.minimap:GetZoom()/4.5
		local wa = math.atan2(ox, oy) - angle
		-- Convert to world x and z coordinates, adding in the offset from the player
		local px, _, pz = GLOBAL.ThePlayer:GetPosition():Get()
		local wx = px - wd*math.cos(wa)
		local wz = pz + wd*math.sin(wa)
		return GLOBAL.Vector3(wx, 0, wz)
	end
end)

--[[ Patch the Map Screen to disable the hovertext when getting closed, and add ping interface]]--
AddClassPostConstruct("screens/mapscreen", function(MapScreen)
	if ENABLEPINGS and GLOBAL.TheInput:ControllerAttached() then
		MapScreen.ping_reticule = MapScreen:AddChild(GLOBAL.require("widgets/uianim")())
		MapScreen.ping_reticule:GetAnimState():SetBank("reticule")
		MapScreen.ping_reticule:GetAnimState():SetBuild("reticule")
		MapScreen.ping_reticule:GetAnimState():PlayAnimation("idle")
		MapScreen.ping_reticule:SetScale(.35)
		local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
		MapScreen.ping_reticule:SetPosition(screenwidth*.5, screenheight*.5)
	end

	local OldOnBecomeInactive = MapScreen.OnBecomeInactive
	function MapScreen:OnBecomeInactive(...)
		self.minimap.nametext:SetString("")
		if ENABLEPINGS then HidePingWheel(true) end -- consider it to be a cancellation
		OldOnBecomeInactive(self, ...)
	end

	if ENABLEPINGS then
        local OldOnMouseButton=MapScreen.OnMouseButton or function()end
		function MapScreen:OnMouseButton(button, down, ...)
			-- Alt-click
			if button == 1000 and down and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
				ShowPingWheel(self.minimap:GetWorldMousePosition())
			end
			return OldOnMouseButton(self,button,down,...)
		end

		local OldOnControl = MapScreen.OnControl
		function MapScreen:OnControl(control, down, ...)
			if control == GLOBAL.CONTROL_MENU_MISC_4 then --right-stick click
				if down then
					ShowPingWheel(self.minimap:GetWorldMousePosition())
				else
					HidePingWheel()
				end
				return true
			end
			return OldOnControl(self, control, down, ...)
		end
		local OldGetHelpText = MapScreen.GetHelpText
		function MapScreen:GetHelpText(...)
			return OldGetHelpText(self, ...) .. "  " .. GLOBAL.TheInput:GetLocalizedControl(
				GLOBAL.TheInput:GetControllerID(), GLOBAL.CONTROL_MENU_MISC_4) .. " Ping"
		end
	end
end)

GLOBAL._GLOBALPOSITIONS_MAP_ICONS = {}

for prefab,data in pairs(TARGET_INDICATOR_ICONS) do
	GLOBAL._GLOBALPOSITIONS_MAP_ICONS[prefab] = prefab .. ".tex"
end

for _,prefab in pairs(GLOBAL.DST_CHARACTERLIST) do
	GLOBAL._GLOBALPOSITIONS_MAP_ICONS[prefab] = prefab .. ".png"
end

--全图定位
AddPlayerPostInit(function(inst) 
    inst:AddTag("compassbearer")
	inst:AddTag("maprevealer")
    inst:AddComponent("maprevealer")	 
	if inst.components.maprevealable ~= nil then
       inst.components.maprevealable:AddRevealSource(inst, "compassbearer")
    end
end)