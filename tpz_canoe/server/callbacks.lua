local TPZ = exports.tpz_core:getCoreAPI()

---------------------------------------------------------------
--[[ Callbacks ]]--
---------------------------------------------------------------

exports.tpz_core:getCoreAPI().addNewCallBack("tpz_canoe:getStoreStatus", function(source, cb, data)

	local BusyStoresList = GetBusyStoresList()
	
	if TPZ.GetTableLength(BusyStoresList) <= 0 then 
		return cb(false) -- not busy 
	end

	for store, _ in pairs(BusyStoresList) do

		if store == data.index then 
			return cb(true)
		end

	end

	return cb(false)

end)

exports.tpz_core:getCoreAPI().addNewCallBack("tpz_canoe:canRentSelectedBoat", function(source, cb, data)
	local _source = source
	local xPlayer = TPZ.GetPlayer(_source)
	local money   = xPlayer.getAccount(0)
	local cost    = Config.Stores[data.index].Canoes[data.vehicle_index].Cost

	if money <= cost then
		SendNotification(_source, Locales['NOT_ENOUGH_MONEY'])
		cb( false )
		return
	end

	xPlayer.removeAccount(0, cost)
	
	SendNotification(_source, Locales['SUCCESSFULLY_RENTED'])

	TriggerClientEvent("tpz_canoe:client:close", _source)
	
	return cb( true )
end)