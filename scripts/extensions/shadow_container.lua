--[[====================================================[==[
    The 'Inter-Shard Pocket' - modification software for
    the game 'Don't Starve Together' by Klei Entertainment.

    Copyright (c) 2023 Fi7iP
    All rights reserved.

    This file is part of the 'Inter-Shard Pocket' software shared under
    the terms of RECEX SHARED SOURCE LICENSE (version 1.0).
    See LICENSE and AUTHORS for more details.
--]==]====================================================]]

--[[
    We except the Master's version of the shadow container to be the main one
    and also the most updated one, since that's where most of the activity will be.

    Openers were limited to 1 in order to prevent any duplication bugs and reduce complexity.
    This allows us to handle the synchronization a lot better since we do not have to handle
    all the rare cases and combinations that come up with multiple openers.
    But it allows a container to be opened by multiple people
    only if all of them are in the same shard.

    The main idea of synchronizing things efficiently is by making the Master shard
    always synchronized and up-to-date while other shards will be synchronized after
    their container is opened.

    TODO:
        - Remove all environmental modifiers for food in the shadow container.
        (probably not really needed since the container has "spoiler" tag anyways)
        - Make the multiple-openers feature to be inter-shard as well.
--]]

--------------------------------
-- [[ Localization ]]
--------------------------------

-- More like "Internet Service Provider"
local ISP = ISP
local ZipAndEncodeString, DecodeAndUnzipString = ZipAndEncodeString, DecodeAndUnzipString
local SpawnSaveRecord = SpawnSaveRecord
local IsTableEmpty = IsTableEmpty
local type = type

--------------------------------
-- [[ Constants ]]
--------------------------------

local MAGICIAN_CONTAINERS = {
    ["magician_chest"] = true,
    ["tophat"] = true,
    ["chester"] = true,
}

local OPEN_TIMEOUT_TIME = 2

--------------------------------
-- [[ Private Variables ]]
--------------------------------

local _ismastershard = TheNet:GetIsMasterSimulation() and TheShard:IsMaster()

-- Those are inner state flags that should be modified only from inside.
-- After disabling this mod it will reset automatically as well.
local _replicated = false -- Whether the shard's items are unique or replicated from Master
local _uptodate = false

--- @type Container
local _sdc
--- @type Task?
local _open_timeout = nil
--- @type table<string, boolean>
local _uptodate_shards
local _opener_queue
if _ismastershard then
    _uptodate_shards = {}
    -- Master should be always up-to-date
    _uptodate = true
else
    _opener_queue = {}
end

-- Flag for ignoring events sent during internal data changes.
local _handling = false
local _disconnected = false

--------------------------------
-- [[ Private Functions ]]
--------------------------------

local function _ShowContainer(doer)
    return _sdc.inst.replica and _sdc.inst.replica.container
        and _sdc.inst.replica.container:AddOpener(doer)
end

local function _HideContainer(doer)
    return _sdc.inst.replica and _sdc.inst.replica.container
        and _sdc.inst.replica.container:RemoveOpener(doer)
end

local function _GetItemReplicationData(item)
    local data = item:GetSaveRecord()

    -- Clear some unnecessary stuff to save some bytes.
    data.y = nil -- defaults to 0
    data.x = nil -- defaults to 0
    data.z = nil -- defaults to 0

    return data
end

local function _GetAllItemsReplicationData()
    local items = {}

    for slot = 1, _sdc.numslots do
        if _sdc.slots[slot] then
            items[slot] = _GetItemReplicationData(_sdc.slots[slot])
        end
    end

    return items
end

local function _GetSyncStringForItem(item)
    return ZipAndEncodeString(_GetItemReplicationData(item))
end

local function _GetAllSyncString()
    return ZipAndEncodeString(_GetAllItemsReplicationData())
end

local function _SendSyncDataTo(shardid)
    print("[ISP] Sending content synchronization data to slave shard:", shardid)

    ISP.SendRPCToShard(
        ISP.RPC.SDC_Sync, shardid, _GetAllSyncString()
    )
end

local function _CloseWithReason(opener, reason)
    _sdc:Close(opener)

    if opener and opener:IsValid() and opener.components.talker then
        opener.components.talker:Say(reason)
    end
end

local function _HandleOpenerQueue(failed, silent)
    for i = #_opener_queue, 1, -1 do
        local opener = _opener_queue[i]
        if type(opener) == "table" and opener:IsValid() then
            if failed == true then
                if not silent then
                    _CloseWithReason(
                        opener, STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.USEMAGICTOOL.UNAVAIBLE
                    )
                end
            else
                _ShowContainer(opener)
            end
        end

        _opener_queue[i] = nil
    end
end

local function _HandleDisconnect()
    if not _sdc:IsOpen() then
        return
    end

    _HandleOpenerQueue(true, true)

    for opener, _ in pairs(_sdc.openlist) do
        _CloseWithReason(opener, STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.USEMAGICTOOL.DISCONNECT)
    end
end

local function _SwitchToGlobalShardProxy(pos)
    -- Maybe not the most ideal solution but should be enought for now.
    _sdc:DropEverything(pos)
    _replicated = true
end

local function _CancelOpenTimeout()
    if _open_timeout then
        _open_timeout:Cancel()
        _open_timeout = nil
    end
end

local function _HandleOpenTimeout()
    _CancelOpenTimeout()

    if _uptodate then
        -- The containers should be already displayed at this point
        return
    end

    _HandleOpenerQueue(true)
end

local function _StartOpenTimeout()
    if not _open_timeout then
        _open_timeout = _sdc.inst:DoTaskInTime(OPEN_TIMEOUT_TIME, _HandleOpenTimeout)
    end
end

local function _ReplicateItems(items)
    for slot = 1, _sdc.numslots do
        if items[slot] then
            local inst = SpawnSaveRecord(items[slot])
            if inst then
                _sdc:GiveItem(inst, slot)
            else
                moderror("Failed to replicate item entity! Data:", DataDumper(items[slot]))
            end
        end
    end
end

local function _UnsyncShards(except)
    if not _uptodate_shards or IsTableEmpty(_uptodate_shards) then
        return -- No shards are up-to-date ignore
    end

    except = tostring(except)
    for shardid, uptodate in pairs(_uptodate_shards) do
        shardid = tostring(shardid)
        if uptodate and shardid ~= except then
            _uptodate_shards[shardid] = nil

            ISP.SendRPCToShard(ISP.RPC.SDC_UpToDate, shardid)
        end
    end
end

-- Should be called only on a slave shard.
local function _HandleSyncData(shardid, data)
    local items = DecodeAndUnzipString(data)
    if type(items) ~= "table" then
        return error("String decoding failed!")
    end

    print("[ISP] Received content synchronization data from Master.")

    _handling = true

    -- Set this before adding the items.
    _uptodate = true
    _sdc:DestroyContents()
    _ReplicateItems(items)

    -- We have updated the server-side data, now show the container to the client.
    -- Unfortunately, this won't prevent the ocassional flickering :/
    _HandleOpenerQueue()
    _CancelOpenTimeout()

    _handling = false
end

local function _CanOpenPocket()
    return (
        not (_sdc._netopened and _sdc._netopened:value()) or
        _sdc:IsOpen()       -- If the container is already open on this shard
    ) and not _disconnected -- this is here as a fallback but we should handle this case separately
end

--------------------------------
-- [[ Event Handlers ]]
--------------------------------

-- Called for itemget, stacksizechange and itemlose events.
local function onslotmodified(inst, data)
    if _handling or POPULATING then
        return
    end

    if _ismastershard then
        -- Tell the slave shards that they are no longer up-to-date!
        _UnsyncShards()
    else
        -- We are syncing content of a slave shard in real time, item by item
        -- because we can't guarantee that the Master will be available
        -- in the future when closing the container.
        local slot = data.slot or (data.item and _sdc:GetItemSlot(data.item))
        if slot then
            -- replication data can be nil when an item is removed.
            local repl_data = data.item and _GetSyncStringForItem(data.item) or nil

            ISP.SendRPCToMaster(ISP.RPC.SDC_SlotModified, tonumber(slot), repl_data)
        end
    end
end

--------------------------------
-- [[ Slave Event Handlers ]]
--------------------------------

local function onopen(inst, data)
    _sdc._netopened:set(true)
    _sdc._netopened:set_local(true)
    if not _ismastershard then
        ISP.SendRPCToMaster(ISP.RPC.SDC_OnOpen)

        -- We except replication at this point.
        -- So prepare for it!
        if not _uptodate then
            local doer = data and data.doer

            _handling = true

            -- We do not have to worry about item overriding
            -- on the Master shard because it's content will
            -- always be synced with the slave shard upon opening.
            if not _replicated then
                print("[ISP] Switching to Global Shard Proxy for Shadow Container...")

                _SwitchToGlobalShardProxy(doer and doer:GetPosition())
            end

            _sdc:DestroyContents()

            _handling = false
        end
    end
end

-- Called when all the openers close the container
local function onclose()
    _sdc._netopened:set(false)
    _sdc._netopened:set_local(false)

    if not _ismastershard then
        _CancelOpenTimeout()

        ISP.SendRPCToMaster(ISP.RPC.SDC_OnClose)
    end
end

--------------------------------
-- [[ Slave RPC Handlers ]]
--------------------------------

ISP.AddShardRPCHandler("SDC_Sync", _HandleSyncData)

ISP.AddShardRPCHandler("SDC_UpToDate", function(shardid, uptodate)
    _uptodate = (uptodate or false)

    -- We have been unsyced so close the container.
    if not _uptodate and _sdc:IsOpen() then
        _sdc:Close()
    end
end)

--------------------------------
-- [[ Master RPC Handlers ]]
--------------------------------

-- This should be only called when a container is opened for the first time.
ISP.AddShardRPCHandler("SDC_OnOpen", function(shardid)
    _sdc._netopened:set(true)

    shardid = tostring(shardid)
    if not _uptodate_shards[shardid] then
        -- Prevent multiple sync requests
        _uptodate_shards[shardid] = true
        _SendSyncDataTo(shardid)
    end
end)

--- @param slot int
--- @param data_str string?
ISP.AddShardRPCHandler("SDC_SlotModified", function(shardid, slot, data_str)
    if type(slot) ~= "number" then
        return moderror("Invalid data recevied for RPC SDC_SlotModified!")
    end

    _handling = true
    local prev_item = _sdc:RemoveItemBySlot(slot)
    if prev_item then
        prev_item:Remove()
    end
    _handling = false

    _UnsyncShards(shardid)

    if type(data_str) ~= "string" then
        return -- No data provided, this is totally valid for itemlose events
    end

    local item_save = DecodeAndUnzipString(data_str)
    if type(item_save) ~= "table" then
        return moderror("Failed do decode replication item data!")
    end

    local item = SpawnSaveRecord(item_save)
    if not item or not item:IsValid() then
        return moderror("Failed to replicate item! Data: " .. tostring(data_str))
    end

    _handling = true
    _sdc:GiveItem(item, slot)
    _handling = false
end)

-- This should be called after all openers close the container.
ISP.AddShardRPCHandler("SDC_OnClose", function(shardid)
    _sdc._netopened:set(false)
end)

--------------------------------
-- [[ Prefab Post Init ]]
--------------------------------

AddPrefabPostInit("shadow_container", function(inst)
    if (not TheWorld or TheWorld.ismastersim ~= true or not TheWorld.shard) then
        return
    end

    _sdc = inst.components.container
    if not (_sdc) then
        return moderror("Missing container component!")
    end

    -- A net boolean that determines whether the container is opened on a shard already or not.
    -- We use the shard entity because it's the only one that has a working ShardNetwork.
    -- Using AddShardNetwork on any other entity will cause some undefined behaviour
    -- and desynchronization of the shards. This is probably a bug.
    _sdc._netopened = net_bool(TheWorld.shard.GUID, "__" .. ISP.MODNAME .. "_shardcontainer_netopened__")

    local _CanOpen = _sdc.CanOpen
    _sdc.CanOpen = function(...)
        return _CanOpenPocket() and _CanOpen(...)
    end

    if not _ismastershard then
        local _GiveItem = _sdc.GiveItem
        _sdc.GiveItem = function(...)
            -- Do not accept items if we are not up-to-date.
            -- This is mainly here for the STORE action,
            --
            -- Ignore this check while populating or
            -- while the container is closed which means
            -- items are being added programatically.
            if POPULATING or not _sdc:IsOpen() or _uptodate then
                return _GiveItem(...)
            end

            return false
        end

        local _Open = _sdc.Open
        _sdc.Open = function(self, doer, ...)
            if not _CanOpenPocket() then
                return false
            end

            _Open(self, doer, ...)

            if not _uptodate then
                -- Hide the container's HUD until we are ready!
                _HideContainer(doer)

                _opener_queue[#_opener_queue + 1] = doer

                _StartOpenTimeout()
            end
        end

        local _OnLoad = _sdc.OnLoad
        _sdc.OnLoad = function(self, data, ...)
            if type(data) == "table" and type(data._replicated) == "boolean" then
                _replicated = data._replicated
            end

            return _OnLoad and _OnLoad(self, data, ...)
        end

        local _OnSave = _sdc.OnSave
        _sdc.OnSave = function(...)
            -- Do not save normally if we were replicated from Master shard.
            -- This is to prevent item duplication when turning this mod off.
            local data = (not _replicated and _OnSave) and _OnSave(...) or nil
            if _replicated then
                data = data or {}
                data._replicated = _replicated
            end

            return data
        end
    end

    -- Use these instead of the events because these
    -- are called only on the first and last opener.
    local _onopenfn = _sdc.onopenfn
    _sdc.onopenfn = function(...)
        onopen(...)

        if type(_onopenfn) == "function" then
            return _onopenfn(...)
        end
    end

    local _onclosefn = _sdc.onclosefn
    _sdc.onclosefn = function(...)
        onclose()

        if type(_onclosefn) == "function" then
            return _onclosefn(...)
        end
    end

    inst:ListenForEvent("itemget", onslotmodified)
    inst:ListenForEvent("stacksizechange", onslotmodified)
    inst:ListenForEvent("itemlose", onslotmodified)
end)

--------------------------------
-- [[ Action Handlers ]]
--------------------------------

-- Special case for the Magician's Top Hat
local _USEMAGICTOOL = ACTIONS.USEMAGICTOOL.fn
ACTIONS.USEMAGICTOOL.fn = function(act, ...)
    if act.invobject and MAGICIAN_CONTAINERS[act.invobject.prefab] then
        if _disconnected then
            return false, "UNAVAIBLE"
        end

        if not _CanOpenPocket() then
            return false, "INUSE"
        end
    end

    return _USEMAGICTOOL(act, ...)
end

--------------------------------
-- [[ Shard State ]]
--------------------------------

local _Shard_UpdateWorldState = rawget(_G, "Shard_UpdateWorldState")
if type(_Shard_UpdateWorldState) == "function" then
    rawset(_G, "Shard_UpdateWorldState", function(world_id, state, ...)
        if not _ismastershard and world_id == SHARDID.MASTER then
            _disconnected = (state == REMOTESHARDSTATE.OFFLINE)

            if _disconnected then
                _HandleDisconnect()
            end
        end

        return _Shard_UpdateWorldState(world_id, state, ...)
    end)
end
