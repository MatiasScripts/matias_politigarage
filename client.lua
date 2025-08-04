local ESX = exports["es_extended"]:getSharedObject()

local npcModel = 's_m_m_security_01'
local npcCoords = vector4(460.0378, -986.6718, 25.6999, 89.3542)

local allowedModels = {}
for _, v in pairs(Config.Vehicles) do
    allowedModels[GetHashKey(v.model)] = true
end

local playerVehicle = nil
local vehicleBlip = nil

-- Variabel til at styre om markeren skal vises
local showMarker = false

local function isSpotFree(coords)
    local vehicles = GetGamePool("CVehicle")
    for _, veh in pairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        if #(vehCoords - vector3(coords.x, coords.y, coords.z)) < Config.SpawnCheckRadius then
            return false
        end
    end
    return true
end

local function startVehicleBlipUpdate(vehicle)
    if vehicleBlip and DoesBlipExist(vehicleBlip) then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end

    vehicleBlip = AddBlipForEntity(vehicle)
    SetBlipSprite(vehicleBlip, 225)
    SetBlipDisplay(vehicleBlip, 4)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipColour(vehicleBlip, 3)
    SetBlipAsShortRange(vehicleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Politibil")
    EndTextCommandSetBlipName(vehicleBlip)

    CreateThread(function()
        while playerVehicle and DoesEntityExist(playerVehicle) do
            local coords = GetEntityCoords(playerVehicle)
            SetBlipCoords(vehicleBlip, coords)
            Wait(5000)
        end

        if vehicleBlip and DoesBlipExist(vehicleBlip) then
            RemoveBlip(vehicleBlip)
            vehicleBlip = nil
        end
    end)
end

local function trySpawnCar(model)
    if playerVehicle and DoesEntityExist(playerVehicle) then
        lib.notify({
            title = 'Politigarage',
            description = 'Du har allerede en politibil ude.',
            type = 'error'
        })
        return
    end

    for i, coords in ipairs(Config.SpawnPoints) do
        if isSpotFree(coords) then
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(100) end

            local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
            SetVehicleNumberPlateText(veh, 'POLITI' .. math.random(100, 999))
            SetEntityAsMissionEntity(veh, true, true)

            playerVehicle = veh
            startVehicleBlipUpdate(veh)

            -- Sæt markeren til at blive vist nu vi har bil ude
            showMarker = true

            lib.notify({
                title = 'Politigarage',
                description = string.format("Din %s er blevet klargjort og placeret på plads %d.", model, i),
                type = 'inform'
            })
            return
        end
    end

    lib.notify({
        title = 'Politigarage',
        description = 'Der er ikke flere ledige pladser. Fjern venligst en anden politibil først.',
        type = 'error'
    })
end

local function removeOwnGarageVehicle()
    if playerVehicle and DoesEntityExist(playerVehicle) then
        DeleteEntity(playerVehicle)
        playerVehicle = nil

        if vehicleBlip and DoesBlipExist(vehicleBlip) then
            RemoveBlip(vehicleBlip)
            vehicleBlip = nil
        end

        -- Skjul markeren når bilen parkeres
        showMarker = false

        lib.notify({
            title = 'Politigarage',
            description = 'Din politibil er nu parkeret.',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Politigarage',
            description = 'Du har ingen aktiv politibil at parkere.',
            type = 'error'
        })
    end
end

-- Marker-draw thread
CreateThread(function()
    while true do
        Wait(0)
        if showMarker then
            local markerPos = vector3(npcCoords.x, npcCoords.y, npcCoords.z + 1.2)
            DrawMarker(
                30,             -- Marker type 27 = Arrow/triangle
                markerPos.x, markerPos.y, markerPos.z,
                0.0, 0.0, 0.0,  -- Direction
                0.0, 0.0, 90.0,  -- Rotation
                0.6, 0.6, 0.6,  -- Scale (size)
                0, 102, 255, 150, -- Color (blå, med transparens)
                false, false, 2,  -- Bobbing, face camera, rotate type
                false, false, false, false -- Misc flags
            )
        else
            Wait(500) -- Hvis markeren ikke vises, kan vi vente længere for performance
        end
    end
end)

CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(100) end

    local npc = CreatePed(0, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcCoords.w, false, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityAsMissionEntity(npc, true, true)

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'garage_menu',
            icon = 'fas fa-warehouse',
            label = 'Tilgå politigaragen',
            onSelect = function()
                local playerData = ESX.GetPlayerData()
                if playerData.job and playerData.job.name == 'police' then
                    local options = {}

                    for _, vehicle in ipairs(Config.Vehicles) do
                        table.insert(options, {
                            title = vehicle.label,
                            icon = 'car',
                            onSelect = function()
                                trySpawnCar(vehicle.model)
                            end
                        })
                    end

                    table.insert(options, {
                        title = 'Luk',
                        icon = 'xmark',
                        event = 'close_menu'
                    })

                    lib.registerContext({
                        id = 'garage_menu',
                        title = 'Politigarage',
                        options = options
                    })

                    lib.showContext('garage_menu')
                else
                    lib.notify({
                        title = 'Adgang nægtet',
                        description = 'Denne garage er kun for politiet.',
                        type = 'error'
                    })
                end
            end
        },
        {
            name = 'garage_remove',
            icon = 'fas fa-parking',
            label = 'Parker din politibil',
            canInteract = function()
                return playerVehicle and DoesEntityExist(playerVehicle)
            end,
            onSelect = function()
                local playerData = ESX.GetPlayerData()
                if playerData.job and playerData.job.name == 'police' then
                    removeOwnGarageVehicle()
                else
                    lib.notify({
                        title = 'Adgang nægtet',
                        description = 'Kun betjente må parkere politibiler her.',
                        type = 'error'
                    })
                end
            end
        }
    })
end)

RegisterNetEvent('close_menu', function()
    lib.hideContext()
end)