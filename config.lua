Config = {}

-- Liste over biler som politiet kan spawne (key = model navn)
Config.Vehicles = {
    {model = 'police', label = 'Passat'},
    {model = 'police2', label = 'Ford'},
    {model = 'police3', label = 'Volvo'}
}

-- Liste over parkeringspladser
Config.SpawnPoints = {
    vector4(445.9910, -986.1147, 25.4546, 270.3271), -- plads 1
    vector4(445.9548, -988.8340, 25.4554, 269.6458), -- plads 2
    vector4(445.9396, -991.6468, 25.4551, 269.6927)  -- plads 3
}

-- Radius til at tjekke om plads er optaget
Config.SpawnCheckRadius = 1.0

-- Radius til at fjerne politibiler
Config.RemoveRadius = 30.0
