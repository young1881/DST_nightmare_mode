--[[====================================================[==[
    The 'Inter-Shard Pocket' - modification software for
    the game 'Don't Starve Together' by Klei Entertainment.

    Copyright (c) 2023 Fi7iP
    All rights reserved.

    This file is part of the 'Inter-Shard Pocket' software shared under
    the terms of RECEX SHARED SOURCE LICENSE (version 1.0).
    See LICENSE and AUTHORS for more details.
--]==]====================================================]]

--------------------------
-- Initialization
--------------------------

ISP.RPC = {
    _size = 0
}

--------------------------
-- RPC Wrappers
--------------------------

function ISP.GetClientRPC(name)
    return GetClientModRPC(ISP.RPC_NAME, name)
end

function ISP.GetShardRPC(name)
    return GetShardModRPC(ISP.RPC_NAME, name)
end

function ISP.GetServerRPC(name)
    return GetModRPC(ISP.RPC_NAME, name)
end

--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param sender_list? table|string|number
--- @param ... any Any additional data provided to the rpc handler.
--- if sender_list is nil, all clients connected to the current shard will execute the RPC.
--- if sender_list is a table, it will be iterated upon and send it to every client that is connected to the current shard thats UserID is in the table.
--- if sender_list is a string, it will send the RPC to the specific client with that UserID, as long as they are connected to that shard.
function ISP.SendRPCToClient(rpc_id, sender_list, ...)
    return SendModRPCToClient(ISP.GetClientRPC(rpc_id), sender_list, ...)
end

--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param sender_list? table|string|number
--- @param ... any Any additional data provided to the rpc handler.
--- if sender_list is nil, all connected shards(including the one this is called on) will have this RPC executed.
--- if sender_list is a table, it will be iterated upon and send it to every shard that's ID is in the table.
--- if sender_list is either a string or a number, it will send that RPC to the specific shard with that ID.
function ISP.SendRPCToShard(rpc_id, sender_list, ...)
    return SendModRPCToShard(ISP.GetShardRPC(rpc_id), sender_list, ...)
end

--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param ... any Any additional data provided to the rpc handler.
function ISP.SendRPCToServer(rpc_id, ...)
    return SendModRPCToServer(ISP.GetServerRPC(rpc_id), ...)
end

--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param ... any Any additional data provided to the rpc handler.
function ISP.SendRPCToMaster(rpc_id, ...)
    return ISP.SendRPCToShard(rpc_id, SHARDID.MASTER, ...)
end

--- Sends the given RPC to all connected shards except the current one.
--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param ... any Any additional data provided to the rpc handler.
function ISP.BroadcastRPCToShards(rpc_id, ...)
    local connected_shards = ISP.ServerNetwork:GetConnectedShardIDs()
    if IsTableEmpty(connected_shards) then
        return
    end

    return ISP.SendRPCToShard(rpc_id, connected_shards, ...)
end

--- @param rpc_id number The identifier of the RPC, these can be found in the mod's RPCS table.
--- @param ... any Any additional data provided to the rpc handler.
function ISP.BroadcastRPCToClients(rpc_id, ...)
    return ISP.SendRPCToClient(rpc_id, nil, ...)
end

------------------------------------

function ISP.AddRPC(name)
    ISP.RPC._size = ISP.RPC._size + 1
    ISP.RPC[name] = ISP.RPC._size

    return ISP.RPC._size
end

function ISP.AddServerUseridRPCHandler(name, handler)
    local id = ISP.AddRPC(name)

    AddModRPCHandler(ISP.RPC_NAME, id, handler)
    MarkUserIDRPC(ISP.RPC_NAME, id)
end

function ISP.AddServerRPCHandler(name, handler)
    return AddModRPCHandler(
        ISP.RPC_NAME, ISP.AddRPC(name), handler
    )
end

function ISP.AddShardRPCHandler(name, handler)
    return AddShardModRPCHandler(
        ISP.RPC_NAME, ISP.AddRPC(name), handler
    )
end

function ISP.AddClientRPCHandler(name, handler)
    ISP.AddRPC(name)
    return AddClientModRPCHandler(
        ISP.RPC_NAME, ISP.AddRPC(name), handler
    )
end
