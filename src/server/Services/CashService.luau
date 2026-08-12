local CashService = {}
local playerDataService

local function isValidAmount(amount)
	return typeof(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
end

function CashService:Init(dataService)
	playerDataService = dataService
end

function CashService:GetCash(player: Player)
	local data = playerDataService:Get(player)
	return if data then data.Cash else nil
end

function CashService:AddCash(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end
	local data = playerDataService:Get(player)
	if not data then
		return false
	end
	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	return true
end

function CashService:CanAfford(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end
	local cash = self:GetCash(player)
	return cash ~= nil and cash >= amount
end

function CashService:SpendCash(player: Player, amount: number): boolean
	if not self:CanAfford(player, amount) then
		return false
	end
	local data = playerDataService:Get(player)
	if not data then
		return false
	end
	data.Cash -= amount
	player:SetAttribute("Cash", data.Cash)
	return true
end

return CashService
