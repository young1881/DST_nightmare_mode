local AddPrefabPostInit = AddPrefabPostInit

GLOBAL.setfenv(1, GLOBAL)

local UpvalueHacker = require "upvaluehacker"

local function FindSkinOwner(skin)
    local has_item, id = TheInventory:CheckClientOwnership(nil, skin or "")

    if has_item and id then
        return id
    end
end

local function ChangeSkin(tool, target, pos, caster)
    target = target or caster --if no target, then self target for beards
    if target == nil then     -- Bail.
        return
    end
    if target.reskin_tool_target_redirect and target.reskin_tool_target_redirect:IsValid() then
        target = target.reskin_tool_target_redirect
    end

    local fx_prefab = "explode_reskin"
    local skin_fx = SKIN_FX_PREFAB[tool:GetSkinName()]
    if skin_fx ~= nil and skin_fx[1] ~= nil then
        fx_prefab = skin_fx[1]
    end

    local fx = SpawnPrefab(fx_prefab)


    local fx_info = tool.GetReskinFXInfo(target)

    local scale_override = fx_info.scale or 1
    local scale_overridex = fx_info.scalex or scale_override
    local scale_overridey = fx_info.scaley or scale_override
    fx.Transform:SetScale(scale_overridex, scale_overridey, scale_overridex)

    local fx_pos_x, fx_pos_y, fx_pos_z = target.Transform:GetWorldPosition()
    fx_pos_y = fx_pos_y + (fx_info.offset or 0)
    fx.Transform:SetPosition(fx_pos_x, fx_pos_y, fx_pos_z)

    tool:DoTaskInTime(0, function()
        local prefab_to_skin = target.prefab
        local is_beard = false
        if target.components.beard ~= nil and target.components.beard.is_skinnable then
            prefab_to_skin = target.prefab .. "_beard"
            is_beard = true
        end

        if target:IsValid() and tool:IsValid() and tool.parent and tool.parent:IsValid() then
            local curr_skin = is_beard and target.components.beard.skinname or target.skinname
            local userid = tool.parent.userid or ""
            local cached_skin = tool._cached_reskinname[prefab_to_skin]
            local search_for_skin = cached_skin ~= nil --also check if it's owned
            if curr_skin == cached_skin or (search_for_skin and not TheInventory:CheckClientOwnership(userid, cached_skin)) then
                local new_reskinname = nil

                if PREFAB_SKINS[prefab_to_skin] ~= nil then
                    local must_have, must_not_have
                    if target.ReskinToolFilterFn ~= nil then
                        must_have, must_not_have = target:ReskinToolFilterFn()
                    end
                    for _, item_type in pairs(PREFAB_SKINS[prefab_to_skin]) do
                        local skip_this = PREFAB_SKINS_SHOULD_NOT_SELECT[item_type] or false
                        if not skip_this then
                            if must_have ~= nil and not StringContainsAnyInArray(item_type, must_have) or must_not_have ~= nil and StringContainsAnyInArray(item_type, must_not_have) then
                                skip_this = true
                            end
                            if not skip_this then
                                if search_for_skin then
                                    if cached_skin == item_type then
                                        search_for_skin = false
                                    end
                                else
                                    local _userid = FindSkinOwner(item_type)
                                    if _userid then
                                        userid = _userid
                                        new_reskinname = item_type
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                tool._cached_reskinname[prefab_to_skin] = new_reskinname
                cached_skin = new_reskinname
            end

            if is_beard then
                target.components.beard:SetSkin(cached_skin)
            else
                TheSim:ReskinEntity(target.GUID, target.skinname, cached_skin, nil, userid)

                if target.prefab == "wormhole" then
                    local other = target.components.teleporter.targetTeleporter
                    if other ~= nil then
                        TheSim:ReskinEntity(other.GUID, other.skinname, cached_skin, nil, userid)
                    end
                elseif target.prefab == "cave_entrance" or target.prefab == "cave_entrance_open" or target.prefab == "cave_exit" then
                    if target.components.worldmigrator:IsLinked() and Shard_IsWorldAvailable(target.components.worldmigrator.linkedWorld) then
                        local skin_theme = ""
                        if target.skinname ~= nil then
                            skin_theme = string.sub(target.skinname, string.len(target.prefab) + 2)
                        end

                        SendRPCToShard(SHARD_RPC.ReskinWorldMigrator, target.components.worldmigrator.linkedWorld,
                            target.components.worldmigrator.id, skin_theme, target.skin_id, TheNet:GetSessionIdentifier())
                    end
                end
            end
        end
    end)
end

AddPrefabPostInit("reskin_tool", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst.GetReskinFXInfo = UpvalueHacker.GetUpvalue(inst.components.spellcaster.spell, "GetReskinFXInfo")
    inst.components.spellcaster:SetSpellFn(ChangeSkin)
end)

client_skin_list = {}
local function OnPlayerListChanged(inst)
    local skins = {}

    for _, skin_list in pairs(PREFAB_SKINS) do
        for _, skin in pairs(skin_list) do
            local skip_this = PREFAB_SKINS_SHOULD_NOT_SELECT[skin] or false
            if not skip_this then
                if TheInventory:CheckClientOwnership(nil, skin) then
                    table.insert(skins, skin)
                end
            end
        end
    end

    local data = DataDumper(skins, nil, true)
    for _, player in ipairs(AllPlayers) do
        if player and player:IsValid() then
            SendModRPCToClient(GetClientModRPC("SKINS", "UPDATE_SKINS_LIST"), player.userid, data)
        end
    end
end

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("ms_playerjoined", OnPlayerListChanged)
    inst:ListenForEvent("ms_playerleft", OnPlayerListChanged)
end)

local _CheckClientOwnership = InventoryProxy.CheckClientOwnership
function InventoryProxy:CheckClientOwnership(id, skin, ...)
    if ThePlayer and ThePlayer:HasTag("debug") then return _CheckClientOwnership(self, id, skin, ...) end

    for k, v in ipairs(TheNet:GetClientTable()) do
        if _CheckClientOwnership(self, v.userid or "", skin or "") then
            return true, v.userid
        end
    end

    if not id or not skin then
        return false
    end

    return _CheckClientOwnership(self, id, skin, ...)
end

local _CheckOwnershipGetLatest = InventoryProxy.CheckOwnershipGetLatest
function InventoryProxy:CheckOwnershipGetLatest(skin, ...)
    if not skin then return false end
    if ThePlayer and ThePlayer:HasTag("debug") then return _CheckOwnershipGetLatest(self, skin, ...) end

    local has_item, modified_time = _CheckOwnershipGetLatest(self, skin, ...)

    for _, cached_skin in ipairs(client_skin_list) do
        if skin == cached_skin then
            return true, modified_time
        end
    end

    return has_item, modified_time
end

local _SpawnPrefab = SpawnPrefab
function SpawnPrefab(name, skin, skin_id, creator, ...)
    if TheWorld and not TheWorld.ismastersim then
        return _SpawnPrefab(name, skin, skin_id, creator, ...)
    end

    creator = FindSkinOwner(skin) or creator
    return _SpawnPrefab(name, skin, skin_id, creator, ...)
end

AddClientModRPCHandler("SKINS", "UPDATE_SKINS_LIST", function(skins)
    if skins and type(skins) == "string" and string.find(skins, "return") then
        client_skin_list = loadstring(skins)()
    end
end)
