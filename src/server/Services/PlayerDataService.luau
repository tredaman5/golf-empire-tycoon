local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataService = {}
local records = {}
local saveLocks = {}
local dataStore
local persistenceEnabled = false

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function defaultData()
	return {
		Cash = Config.StartingCash,
		OwnedBuildings = {},
		BayCount = 0,
		PricingStrategy = Config.DrivingRange.DefaultPricingStrategy,
		CustomersServed = 0,
		LifetimeRevenue = 0,
		PuttingGreenOwned = false,
		PlotId = nil,
	}
end

local function sanitizeSavedData(saved)
	if saved == nil then
		return defaultData()
	end
	if typeof(saved) ~= "table" then
		return nil, "Saved data is not a table."
	end
	local schemaVersion = saved.SchemaVersion
	if schemaVersion ~= 1 and schemaVersion ~= 2 and schemaVersion ~= Config.DataStore.SchemaVersion then
		return nil, `Unsupported data schema version: {tostring(schemaVersion)}`
	end
	if not isFiniteNumber(saved.Cash) or saved.Cash < 0 then
		return nil, "Saved cash is invalid."
	end
	if typeof(saved.OwnedBuildings) ~= "table" then
		return nil, "Saved buildings are invalid."
	end

	local ownedBuildings = {}
	for buildingId, owned in saved.OwnedBuildings do
		if typeof(buildingId) == "string" and owned == true and Config.Buildings[buildingId] then
			ownedBuildings[buildingId] = true
		end
	end
	local bayCount = if schemaVersion == 1
		then (if ownedBuildings.DrivingRangeBay then 1 else 0)
		else saved.BayCount
	if typeof(bayCount) ~= "number" or bayCount % 1 ~= 0 or bayCount < 0 or bayCount > Config.DrivingRange.MaxBayCount then
		return nil, "Saved bay count is invalid."
	end
	local pricingStrategy = if schemaVersion == 1 then Config.DrivingRange.DefaultPricingStrategy else saved.PricingStrategy
	if typeof(pricingStrategy) ~= "string" or not Config.DrivingRange.PricingStrategies[pricingStrategy] then
		return nil, "Saved pricing strategy is invalid."
	end
	local customersServed = if schemaVersion < 3 then 0 else saved.CustomersServed
	local lifetimeRevenue = if schemaVersion < 3 then 0 else saved.LifetimeRevenue
	local puttingGreenOwned = if schemaVersion < 3 then false else saved.PuttingGreenOwned
	if typeof(customersServed) ~= "number" or customersServed % 1 ~= 0 or customersServed < 0 then
		return nil, "Saved customer count is invalid."
	end
	if not isFiniteNumber(lifetimeRevenue) or lifetimeRevenue < 0 or typeof(puttingGreenOwned) ~= "boolean" then
		return nil, "Saved progression is invalid."
	end
	return {
		Cash = math.floor(saved.Cash),
		OwnedBuildings = ownedBuildings,
		BayCount = bayCount,
		PricingStrategy = pricingStrategy,
		CustomersServed = customersServed,
		LifetimeRevenue = math.floor(lifetimeRevenue),
		PuttingGreenOwned = puttingGreenOwned,
		PlotId = nil,
	}
end

local function serializeData(data)
	local ownedBuildings = {}
	for buildingId, owned in data.OwnedBuildings do
		if owned == true and Config.Buildings[buildingId] then
			ownedBuildings[buildingId] = true
		end
	end
	return {
		SchemaVersion = Config.DataStore.SchemaVersion,
		Cash = math.max(0, math.floor(data.Cash)),
		OwnedBuildings = ownedBuildings,
		BayCount = data.BayCount,
		PricingStrategy = data.PricingStrategy,
		CustomersServed = data.CustomersServed,
		LifetimeRevenue = data.LifetimeRevenue,
		PuttingGreenOwned = data.PuttingGreenOwned,
	}
end

local function retry(operationName, callback)
	local lastError
	for attempt = 1, Config.DataStore.RetryCount do
		local success, result = pcall(callback)
		if success then
			return true, result
		end
		lastError = result
		warn(`DataStore {operationName} attempt {attempt} failed: {tostring(result)}`)
		if attempt < Config.DataStore.RetryCount then
			task.wait(Config.DataStore.RetryDelay * attempt)
		end
	end
	return false, lastError
end

function PlayerDataService:Init()
	persistenceEnabled = not RunService:IsStudio() or Config.DataStore.EnableInStudio
	if persistenceEnabled then
		local storeName = if RunService:IsStudio() then Config.DataStore.StudioName else Config.DataStore.Name
		dataStore = DataStoreService:GetDataStore(storeName)
	else
		warn("DataStore persistence is disabled in Studio; this session will not load or save cloud data.")
	end
end

function PlayerDataService:Load(player: Player): boolean
	if records[player] then
		return true
	end
	player:SetAttribute("DataLoaded", false)

	local data
	if persistenceEnabled then
		local key = Config.DataStore.KeyPrefix .. player.UserId
		local success, saved = retry("load", function()
			return dataStore:GetAsync(key)
		end)
		if not success then
			warn(`Unable to load data for {player.Name}; saving will remain disabled for this player.`)
			return false
		end
		local validationError
		data, validationError = sanitizeSavedData(saved)
		if not data then
			warn(`Unable to use data for {player.Name}: {validationError}`)
			return false
		end
	else
		data = defaultData()
	end

	records[player] = data
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("PricingStrategy", data.PricingStrategy)
	player:SetAttribute("CustomersServed", data.CustomersServed)
	player:SetAttribute("LifetimeRevenue", data.LifetimeRevenue)
	player:SetAttribute("BayCount", data.BayCount)
	player:SetAttribute("PuttingGreenOwned", data.PuttingGreenOwned)
	player:SetAttribute("DataLoaded", true)
	return true
end

function PlayerDataService:Get(player: Player)
	return records[player]
end

function PlayerDataService:Save(player: Player): boolean
	local data = records[player]
	if not data or not persistenceEnabled then
		return data ~= nil
	end

	while saveLocks[player] do
		task.wait(0.1)
		data = records[player]
		if not data then
			return false
		end
	end
	saveLocks[player] = true
	local snapshot = serializeData(data)
	local key = Config.DataStore.KeyPrefix .. player.UserId
	local blockedByNewerSchema = false
	local success = retry("save", function()
		return dataStore:UpdateAsync(key, function(current)
			if typeof(current) == "table" and typeof(current.SchemaVersion) == "number"
				and current.SchemaVersion > Config.DataStore.SchemaVersion then
				blockedByNewerSchema = true
				return nil
			end
			return snapshot
		end)
	end)
	saveLocks[player] = nil
	if blockedByNewerSchema then
		warn(`Refused to overwrite newer saved data for {player.Name}.`)
		return false
	end
	return success
end

function PlayerDataService:StartAutosave()
	task.spawn(function()
		while task.wait(Config.DataStore.AutosaveInterval) do
			for player in records do
				task.spawn(function()
					if not self:Save(player) then
						warn(`Autosave failed for {player.Name}.`)
					end
				end)
			end
		end
	end)
end

function PlayerDataService:Remove(player: Player)
	records[player] = nil
	saveLocks[player] = nil
end

function PlayerDataService:IsPersistenceEnabled(): boolean
	return persistenceEnabled
end

return PlayerDataService
