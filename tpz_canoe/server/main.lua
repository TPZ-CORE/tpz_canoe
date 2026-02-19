local TPZ = exports.tpz_core:getCoreAPI()
local BusyStoresList = {}

---------------------------------------------------------------
--[[ Callbacks ]]--
---------------------------------------------------------------

function GetBusyStoresList()
	return BusyStoresList
end

---------------------------------------------------------------
--[[ Events ]]--
---------------------------------------------------------------


AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

	BusyStoresList = nil
end)

RegisterServerEvent('tpz_canoe:server:start_building')
AddEventHandler('tpz_canoe:server:start_building', function(index)
	local coords = vector3(Config.Stores[index].SpawnCoords.x, Config.Stores[index].SpawnCoords.y, Config.Stores[index].SpawnCoords.z)
	TPZ.TriggerClientEventToCoordsOnly("tpz_canoe:client:start_building", { index = index }, coords, 50.0)
end)

RegisterServerEvent('tpz_canoe:server:setBusyState')
AddEventHandler('tpz_canoe:server:setBusyState', function(index, cb)
	
	BusyStoresList[index] = cb

	if cb == false then 
		BusyStoresList[index] = nil
	end

end)