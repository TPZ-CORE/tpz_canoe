local MenuData = {}
TriggerEvent("tpz_menu_base:getData", function(call) MenuData = call end)

local CATEGORIES_BUY_TITLE_STYLE <const>      = "<span style='opacity: 0.8; float:right; text-align: right; font-size: 0.8vw; margin-top: -0.20vw;' >%s</span>"

local CATEGORIES_BUY_CASH_IMAGE_PATH <const>  = "<img style='max-height:2.3vw;max-width:2.3vw; float:%s; margin-top: -0.25vw;' src='nui://tpz_stables/html/img/%s.png'>"
local CATEGORIES_BUY_CASH_TEXT_PATH <const>   = "<span style='opacity: 0.8; float:left; text-align: left; width: 2.5vw; font-size: 0.8vw; margin-top: -0.20vw; margin-left: 0.25vw;' >%s</span>"

------------------------------------------------------------------
-- Local Functions
------------------------------------------------------------------

local function StartRentingProccess(data)

	local locationIndex = GetPlayerData().LocationIndex

	local data = {
		model         = data.model, 
		name          = data.name,
		index         = locationIndex,
		vehicle_index = data.index,
	}

	local cb = exports.tpz_core:ClientRpcCall().Callback.TriggerAwait('tpz_canoe:canRentSelectedBoat', data )
	
	if cb then

		local coords = Config.Stores[locationIndex].SpawnCoords

		TriggerServerEvent("tpz_canoe:server:start_building", locationIndex)

		Wait(20000)
		
		DeleteEntity(brokenVehicleEntity)

		Wait(2000)

		LoadModel(data.model)

		local vehicleEntity = CreateVehicle(data.model, coords.x, coords.y, coords.z, coords.h, true, false)

		Citizen.InvokeNative(0x283978A15512B2FE, vehicleEntity, true)
		SetModelAsNoLongerNeeded(data.model)

		TriggerServerEvent("tpz_canoe:server:setBusyState", locationIndex, false)

		TriggerEvent("tp_lib:sendNotification","Your canoe is ready, please come and carry it away.", {r = 211, g = 211, b = 211, a = 255}, 500)
	end

end


------------------------------------------------------------------
-- Functions
------------------------------------------------------------------

OpenCanoeRentingShop = function(index, title)

    MenuData.CloseAll()

	local PlayerData = GetPlayerData()
	
	local player = PlayerPedId()
	local cb     = exports.tpz_core:ClientRpcCall().Callback.TriggerAwait('tpz_canoe:getStoreStatus', { index = index } )

	if cb then
		SendNotification(nil, Locales['STORE_BUSY'])
		return
	end

	local coords         = Config.Stores[index].SpawnCoords
	local closestVehicle = GetClosestVehicle(coords)
	local entityModel    = GetEntityModel(closestVehicle)
	local isModelCanoe   = IsModelCanoe(entityModel)

	if isModelCanoe then
		SendNotification(nil, Locales['STORE_PICKUP'])
		return
	end

	PlayerData.IsBusy = true
	PlayerData.LocationIndex = index
	TaskStandStill(PlayerPedId(), -1)

	TriggerServerEvent("tpz_canoe:server:setBusyState", index, true)
	TriggerEvent("tpz_canoe:client:menu_tasks")

	local elements = {}

	for k, v in pairs(Config.Stores[index].Canoes) do

		local desc_html = "<img src='nui://tpz_canoe/html/img/" .. v.ImageBackground .. "' /><br><br>" ..
		"<span style='color: aliceblue; font-size: 1.1vw; font-weight: bold; text-decoration: underline;'>".. v.DescriptionTitle .. "</span><br><br>" ..
		"<span style='color: white; font-size: 0.8vw; font-weight: bold;'>".. v.Description .. "</span><br><br>"

		local cashIcon = CATEGORIES_BUY_CASH_IMAGE_PATH:format("left", "money")
		local cashText = CATEGORIES_BUY_CASH_TEXT_PATH:format(v.Cost)
		local title    = CATEGORIES_BUY_TITLE_STYLE:format(v.Title)

		local html = (title .. cashIcon .. cashText)
		
		table.insert(elements, { 
			label = html, 
			value = k,
			desc  = desc_html,
			index = k,
			model = v.Model,
			name  = v.Title,
		})

	end


	table.insert(elements, { value = "exit", label = Locales['MENU_EXIT'], desc = desc})

	MenuData.Open('default', GetCurrentResourceName(), 'canoes',

    {
        title    = title,
        subtext  = "",
        align    = "left",
        elements = elements,
        lastmenu = "notMenu"
    },

    function(data, menu)
        if (data.current == "backup" or data.current.value == "exit") then 
			menu.close()
			PlayerData.IsBusy = false
			PlayerData.LocationIndex = nil
			TaskStandStill(PlayerPedId(), 1)

			TriggerServerEvent("tpz_canoe:server:setBusyState", index, false)
            return
        end

		StartRentingProccess( data.current )
		
    end,

    function(data, menu)
        menu.close()
        PlayerData.IsBusy = false
		PlayerData.LocationIndex = nil
        TaskStandStill(PlayerPedId(), 1)
		
		TriggerServerEvent("tpz_canoe:server:setBusyState", index, false)
    end)

end

------------------------------------------------------------------
-- Events
------------------------------------------------------------------

RegisterNetEvent("tpz_canoe:client:close") 
AddEventHandler("tpz_canoe:client:close", function() 
    MenuData.CloseAll()
	
	local PlayerData = GetPlayerData()

	PlayerData.IsBusy = false
	PlayerData.LocationIndex = nil
	TaskStandStill(PlayerPedId(), 1)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

	local PlayerData = GetPlayerData()

	if PlayerData.IsBusy then 
		MenuData.CloseAll()
	end

end)

RegisterNetEvent("tpz_canoe:client:start_building")
AddEventHandler("tpz_canoe:client:start_building", function(data)

	local index = data.index

	LoadModel('p_canoeconst01x')

	local coords = Config.Stores[index].SpawnCoords
	local brokenVehicleEntity = CreateObject('p_canoeconst01x', coords.x, coords.y, coords.z, false, false)
	SetEntityHeading(brokenVehicleEntity, coords.h)

	Wait(250)
	FreezeEntityPosition(brokenVehicleEntity, true)
	
	local npc = Config.Stores[index].NPC

	exports.tpz_core:getCoreAPI().PlayAnimation(npc, { 
		dict = "amb_work@world_human_hammer@table@male_a@idle_b", 
		name = "idle_e",
		blendInSpeed = 1.0,
		blendOutSpeed = 1.0,
		duration = -1,
		flag = 31,
		playbackRate = 0.0
	})

	Wait(19 * 1000)

	exports.tpz_core:getCoreAPI().RemoveEntityProperly(brokenVehicleEntity, joaat('p_canoeconst01x'))

	Wait(1000)
	StopAnimTask(npc, "amb_work@world_human_hammer@table@male_a@idle_b", "idle_e", 31)
end)

AddEventHandler('tpz_canoe:client:menu_tasks', function()

	Citizen.CreateThread(function()

		while GetPlayerData().IsBusy do 
			Wait(1)
			DisplayRadar(false)
		end

	end)

end)