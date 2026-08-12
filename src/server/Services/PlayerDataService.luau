local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataService = {}
local records = {}

function PlayerDataService:Create(player: Player)
	if records[player] then
		return records[player]
	end

	local data = {
		Cash = Config.StartingCash,
		OwnedBuildings = {},
		PlotId = nil,
	}
	records[player] = data
	player:SetAttribute("Cash", data.Cash)
	return data
end

function PlayerDataService:Get(player: Player)
	return records[player]
end

function PlayerDataService:Remove(player: Player)
	records[player] = nil
end

return PlayerDataService
