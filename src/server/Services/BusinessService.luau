local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local BusinessService = {}
local playerDataService
local cashService
local plotService
local customerService
local feedbackEvent
local managementEvent
local purchaseLocks = {}
local proShopIncomeActive = {}

local function makePart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Parent = parent
	return part
end

local function createPropertyLayout(parent, origin)
	local layout = Instance.new("Model")
	layout.Name = "PropertyLayout"
	layout.Parent = parent

	local function createParkedCar(name, position, color)
		local car = Instance.new("Model")
		car.Name = name
		car.Parent = layout
		local body = makePart(car, "Body", Vector3.new(6.5, 1.5, 10), position + Vector3.new(0, 1.5, 0), color)
		body.Material = Enum.Material.SmoothPlastic
		local cabin = makePart(car, "Cabin", Vector3.new(5.4, 2.2, 5), position + Vector3.new(0, 3.1, 0.5), Color3.fromRGB(42, 55, 62))
		cabin.Material = Enum.Material.Glass
		cabin.Transparency = 0.2
		for _, offset in { Vector3.new(-3.3, 0.8, -3), Vector3.new(3.3, 0.8, -3), Vector3.new(-3.3, 0.8, 3), Vector3.new(3.3, 0.8, 3) } do
			local wheel = makePart(car, "Wheel", Vector3.new(1, 2.2, 2.2), position + offset, Color3.fromRGB(28, 30, 30))
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Material = Enum.Material.Rubber
		end
	end

	local function createGolfCart(name, position, color)
		local cart = Instance.new("Model")
		cart.Name = name
		cart.Parent = layout
		local base = makePart(cart, "Base", Vector3.new(5, 1, 8), position + Vector3.new(0, 1.2, 0), color)
		base.Material = Enum.Material.SmoothPlastic
		local floor = makePart(cart, "Floor", Vector3.new(4.5, 0.4, 5.5), position + Vector3.new(0, 2, 0), Color3.fromRGB(55, 62, 60))
		floor.Material = Enum.Material.Metal
		local seat = makePart(cart, "Seat", Vector3.new(4.2, 1.2, 1.8), position + Vector3.new(0, 2.8, 0.8), Color3.fromRGB(225, 220, 195))
		seat.Material = Enum.Material.Fabric
		local roof = makePart(cart, "Roof", Vector3.new(5.4, 0.4, 7), position + Vector3.new(0, 6.2, 0), Color3.fromRGB(235, 235, 220))
		roof.Material = Enum.Material.SmoothPlastic
		for _, x in { -2, 2 } do
			for _, z in { -2.5, 2.5 } do
				local support = makePart(cart, "RoofSupport", Vector3.new(0.25, 4, 0.25), position + Vector3.new(x, 4.1, z), Color3.fromRGB(60, 68, 65))
				support.Material = Enum.Material.Metal
			end
		end
		for _, offset in { Vector3.new(-2.5, 0.8, -2.6), Vector3.new(2.5, 0.8, -2.6), Vector3.new(-2.5, 0.8, 2.6), Vector3.new(2.5, 0.8, 2.6) } do
			local wheel = makePart(cart, "Wheel", Vector3.new(0.8, 1.8, 1.8), position + offset, Color3.fromRGB(28, 30, 30))
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Material = Enum.Material.Rubber
		end
	end

	createParkedCar("GuestCar1", origin + Vector3.new(-55, 0.7, -65), Color3.fromRGB(50, 105, 165))
	createParkedCar("GuestCar2", origin + Vector3.new(-37, 0.7, -65), Color3.fromRGB(175, 65, 55))
	createGolfCart("PropertyCart1", origin + Vector3.new(38, 0.7, -68), Color3.fromRGB(35, 115, 65))
	createGolfCart("PropertyCart2", origin + Vector3.new(52, 0.7, -68), Color3.fromRGB(35, 115, 65))

	local waitingLane = makePart(layout, "CustomerWaitingLane", Vector3.new(12, 0.16, 32), origin + Vector3.new(0, 0.82, -16), Color3.fromRGB(175, 170, 155))
	waitingLane.Material = Enum.Material.Pavement
	local puttingWaitingLane = makePart(layout, "PuttingWaitingLane", Vector3.new(30, 0.16, 7), origin + Vector3.new(30, 0.82, -18), Color3.fromRGB(175, 170, 155))
	puttingWaitingLane.Material = Enum.Material.Pavement
	local rangeExitPath = makePart(layout, "RangeCustomerExitPath", Vector3.new(7, 0.16, 30), origin + Vector3.new(-18, 0.8, -33), Color3.fromRGB(205, 194, 165))
	rangeExitPath.Material = Enum.Material.Cobblestone
	local puttingExitPath = makePart(layout, "PuttingCustomerExitPath", Vector3.new(7, 0.16, 30), origin + Vector3.new(60, 0.8, -33), Color3.fromRGB(205, 194, 165))
	puttingExitPath.Material = Enum.Material.Cobblestone
	local puttingPath = makePart(layout, "PuttingGreenPath", Vector3.new(7, 0.16, 46), origin + Vector3.new(50, 0.8, 4), Color3.fromRGB(205, 194, 165))
	puttingPath.Material = Enum.Material.Cobblestone
	local kioskPatio = makePart(layout, "ManagementPatio", Vector3.new(18, 0.18, 14), origin + Vector3.new(48, 0.78, -28), Color3.fromRGB(175, 170, 155))
	kioskPatio.Material = Enum.Material.Pavement

	for _, x in { -7, 7 } do
		local rail = makePart(layout, "QueueRail", Vector3.new(0.25, 0.2, 27), origin + Vector3.new(x, 1.55, -16.5), Color3.fromRGB(50, 65, 62))
		rail.Material = Enum.Material.Metal
		for _, z in { -30, -21, -12, -3 } do
			local post = makePart(layout, "QueuePost", Vector3.new(0.35, 2.2, 0.35), origin + Vector3.new(x, 1.35, z), Color3.fromRGB(50, 65, 62))
			post.Material = Enum.Material.Metal
		end
	end
	for _, z in { -22, -14 } do
		local rail = makePart(layout, "PuttingQueueRail", Vector3.new(30, 0.2, 0.25), origin + Vector3.new(30, 1.55, z), Color3.fromRGB(50, 65, 62))
		rail.Material = Enum.Material.Metal
	end

	local clubhouseLawn = makePart(layout, "FutureClubhouseLawn", Vector3.new(30, 0.12, 24), origin + Vector3.new(-48, 0.72, -4), Color3.fromRGB(67, 132, 63))
	clubhouseLawn.Material = Enum.Material.Grass
	for _, offset in { Vector3.new(-64, 1.6, -15), Vector3.new(-32, 1.6, -15), Vector3.new(-64, 1.6, 8), Vector3.new(-32, 1.6, 8) } do
		local shrub = makePart(layout, "DevelopmentShrub", Vector3.new(4, 3, 4), origin + offset, Color3.fromRGB(40, 112, 54))
		shrub.Shape = Enum.PartType.Ball
		shrub.Material = Enum.Material.Grass
	end

	local lounge = makePart(layout, "GuestLoungePatio", Vector3.new(20, 0.16, 12), origin + Vector3.new(48, 0.77, -5), Color3.fromRGB(190, 185, 170))
	lounge.Material = Enum.Material.Pavement
	for _, x in { 41, 55 } do
		local bench = makePart(layout, "LoungeBench", Vector3.new(6, 0.7, 1.5), origin + Vector3.new(x, 1.6, -8), Color3.fromRGB(68, 82, 78))
		bench.Material = Enum.Material.Metal
	end
end

local function createFacility(parent, origin, bayCount)
	local old = parent:FindFirstChild("DrivingRangeFacility")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "DrivingRangeFacility"
	model.Parent = parent
	local width = bayCount * 16
	local foundation = makePart(model, "StoneFoundation", Vector3.new(width, 0.8, 14), origin + Vector3.new(0, 0.9, 8), Color3.fromRGB(185, 178, 155))
	foundation.Material = Enum.Material.Slate
	local canopy = makePart(model, "SharedCanopy", Vector3.new(width + 3, 0.8, 12), origin + Vector3.new(0, 9, 7), Color3.fromRGB(35, 48, 52))
	canopy.Material = Enum.Material.Metal
	local rearBeam = makePart(model, "RearSupportBeam", Vector3.new(width + 2, 0.65, 0.65), origin + Vector3.new(0, 7.8, 2.2), Color3.fromRGB(225, 230, 225))
	rearBeam.Material = Enum.Material.Metal
	for _, x in { -(width / 2), width / 2 } do
		local column = makePart(model, "CanopyColumn", Vector3.new(0.65, 8, 0.65), origin + Vector3.new(x, 4.8, 2.2), Color3.fromRGB(225, 230, 225))
		column.Material = Enum.Material.Metal
	end

	local rangeField = makePart(model, "RangeField", Vector3.new(64, 0.35, 78), origin + Vector3.new(0, 0.7, 54), Color3.fromRGB(72, 145, 67))
	rangeField.Material = Enum.Material.Grass
	local fairway = makePart(model, "FairwayStripe", Vector3.new(22, 0.08, 76), origin + Vector3.new(0, 0.92, 54), Color3.fromRGB(82, 158, 72))
	fairway.Material = Enum.Material.Grass

	local function createTarget(name, x, z, diameter, color)
		local target = makePart(model, name, Vector3.new(0.18, diameter, diameter), origin + Vector3.new(x, 1.02, z), color)
		target.Shape = Enum.PartType.Cylinder
		target.Orientation = Vector3.new(0, 0, 90)
		target.Material = Enum.Material.SmoothPlastic
		local center = makePart(model, `{name}Center`, Vector3.new(0.2, diameter * 0.35, diameter * 0.35), origin + Vector3.new(x, 1.14, z), Color3.fromRGB(245, 245, 235))
		center.Shape = Enum.PartType.Cylinder
		center.Orientation = Vector3.new(0, 0, 90)
	end

	createTarget("NearTarget", -13, 31, 8, Color3.fromRGB(65, 115, 205))
	createTarget("MidTarget", 14, 55, 11, Color3.fromRGB(225, 170, 45))
	createTarget("FarTarget", -7, 82, 14, Color3.fromRGB(205, 70, 60))

	local leftNet = makePart(model, "LeftSafetyNet", Vector3.new(0.25, 20, 78), origin + Vector3.new(-32.5, 10.5, 54), Color3.fromRGB(25, 70, 45))
	local rightNet = makePart(model, "RightSafetyNet", Vector3.new(0.25, 20, 78), origin + Vector3.new(32.5, 10.5, 54), Color3.fromRGB(25, 70, 45))
	local backNet = makePart(model, "BackSafetyNet", Vector3.new(65, 20, 0.25), origin + Vector3.new(0, 10.5, 93), Color3.fromRGB(25, 70, 45))
	for _, net in { leftNet, rightNet, backNet } do
		net.CanCollide = false
		net.Material = Enum.Material.Fabric
		net.Transparency = 0.55
	end
	for _, x in { -32.5, 32.5 } do
		for _, z in { 15, 54, 93 } do
			local pole = makePart(model, "SafetyNetPole", Vector3.new(0.5, 22, 0.5), origin + Vector3.new(x, 11.5, z), Color3.fromRGB(45, 50, 48))
			pole.Material = Enum.Material.Metal
		end
	end
	for bayIndex = 1, bayCount do
		local xOffset = (bayIndex - (bayCount + 1) / 2) * 16
		local bayOrigin = origin + Vector3.new(xOffset, 0, 0)
		local bay = Instance.new("Model")
		bay.Name = `Bay{bayIndex}`
		bay.Parent = model
		makePart(bay, "HittingMat", Vector3.new(10, 0.5, 8), bayOrigin + Vector3.new(0, 1, 8), Color3.fromRGB(35, 105, 45))
		if bayIndex < bayCount then
			local divider = makePart(bay, "StationDivider", Vector3.new(0.3, 2.5, 8), bayOrigin + Vector3.new(8, 2.4, 7), Color3.fromRGB(70, 85, 82))
			divider.Material = Enum.Material.Metal
		end
		local basket = makePart(bay, "BallBasket", Vector3.new(1.8, 1.2, 1.8), bayOrigin + Vector3.new(4, 1.8, 5), Color3.fromRGB(225, 190, 65))
		basket.Material = Enum.Material.Metal
		local bench = makePart(bay, "Bench", Vector3.new(4, 0.6, 1.5), bayOrigin + Vector3.new(-3.5, 2, 3.5), Color3.fromRGB(70, 85, 82))
		bench.Material = Enum.Material.Metal
	end
end

local function addPrompt(parent, actionText, objectText, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	prompt.Triggered:Connect(callback)
	return prompt
end

function BusinessService:Init(dataService, cash, plots, customers, remote, managementRemote)
	playerDataService = dataService
	cashService = cash
	plotService = plots
	customerService = customers
	feedbackEvent = remote
	managementEvent = managementRemote
	managementEvent.OnServerEvent:Connect(function(player, action, value)
		if action ~= "SetPricing" or typeof(value) ~= "string" or not Config.DrivingRange.PricingStrategies[value] then return end
		local data = playerDataService:Get(player)
		if not data or not data.OwnedBuildings.DrivingRangeBay or not plotService:GetPlayerPlot(player) then return end
		data.PricingStrategy = value
		player:SetAttribute("PricingStrategy", value)
		feedbackEvent:FireClient(player, `{value} pricing selected.`)
	end)
end

function BusinessService:_createManagementControls(player, content, plot)
	local data = playerDataService:Get(player)
	if not data then
		return
	end
	local kiosk = makePart(content, "ManagementKiosk", Vector3.new(6, 5, 4), plot.Origin + Vector3.new(48, 3, -28), Color3.fromRGB(25, 75, 45))
	kiosk.Material = Enum.Material.WoodPlanks
	local kioskRoof = makePart(content, "ManagementKioskRoof", Vector3.new(8, 0.8, 6), plot.Origin + Vector3.new(48, 6, -28), Color3.fromRGB(45, 48, 42))
	kioskRoof.Material = Enum.Material.Slate
	local screen = makePart(content, "ManagementScreen", Vector3.new(3.5, 2.2, 0.2), plot.Origin + Vector3.new(48, 3.7, -25.9), Color3.fromRGB(70, 170, 115))
	screen.Material = Enum.Material.Neon
	addPrompt(kiosk, "Open Dashboard", "Golf Business Management", function(triggeringPlayer)
		if triggeringPlayer ~= player or not plotService:OwnsPlot(player, plot.Id) then
			feedbackEvent:FireClient(triggeringPlayer, "You can only manage your own property.")
			return
		end
		managementEvent:FireClient(player, "Open")
	end)

	if data.BayCount < Config.DrivingRange.MaxBayCount then
		local nextBayCount = data.BayCount + 1
		local price = Config.DrivingRange.BayUpgradePrices[nextBayCount]
		local upgradePad = makePart(content, "NextBayUpgradePad", Vector3.new(12, 1, 12), plot.Origin + Vector3.new(-20, 1, -28), Color3.fromRGB(70, 160, 220))
		addPrompt(upgradePad, `Build Bay {nextBayCount} - ${price}`, "Driving Range Expansion", function(triggeringPlayer)
			self:PurchaseNextBay(triggeringPlayer, plot.Id)
		end)
	end
	self:RefreshProgression(player)
end

local function createPuttingGreen(content, origin)
	if content:FindFirstChild("PuttingGreen") then return end
	local model = Instance.new("Model")
	model.Name = "PuttingGreen"
	model.Parent = content
	local fringe = makePart(model, "Fringe", Vector3.new(0.5, 28, 28), origin + Vector3.new(50, 0.85, 25), Color3.fromRGB(64, 128, 58))
	fringe.Shape = Enum.PartType.Cylinder
	fringe.Orientation = Vector3.new(0, 0, 90)
	fringe.Material = Enum.Material.Grass
	local green = makePart(model, "Green", Vector3.new(0.6, 23, 23), origin + Vector3.new(50, 1.15, 25), Color3.fromRGB(48, 155, 68))
	green.Shape = Enum.PartType.Cylinder
	green.Orientation = Vector3.new(0, 0, 90)
	green.Material = Enum.Material.Grass
	makePart(model, "Cup", Vector3.new(1.2, 0.2, 1.2), origin + Vector3.new(53, 1.4, 27), Color3.fromRGB(20, 20, 20))
	makePart(model, "FlagPole", Vector3.new(0.25, 8, 0.25), origin + Vector3.new(53, 5, 27), Color3.fromRGB(235, 235, 235))
	makePart(model, "Flag", Vector3.new(3, 2, 0.2), origin + Vector3.new(54.5, 8, 27), Color3.fromRGB(225, 55, 45))
end

local function createProShop(content, origin)
	if content:FindFirstChild("ProShop") then return end
	local model = Instance.new("Model")
	model.Name = "ProShop"
	model.Parent = content
	local center = origin + Vector3.new(-48, 0, -4)
	local floor = makePart(model, "ShopFloor", Vector3.new(30, 0.8, 24), center + Vector3.new(0, 1, 0), Color3.fromRGB(185, 180, 165))
	floor.Material = Enum.Material.Slate
	local roof = makePart(model, "ShopRoof", Vector3.new(32, 0.8, 26), center + Vector3.new(0, 10, 0), Color3.fromRGB(35, 48, 52))
	roof.Material = Enum.Material.Metal
	local backWall = makePart(model, "BackWall", Vector3.new(30, 9, 0.7), center + Vector3.new(0, 5.5, 11.5), Color3.fromRGB(225, 226, 214))
	backWall.Material = Enum.Material.Concrete
	for _, x in { -14.5, 14.5 } do
		local wall = makePart(model, "SideWall", Vector3.new(0.7, 9, 24), center + Vector3.new(x, 5.5, 0), Color3.fromRGB(225, 226, 214))
		wall.Material = Enum.Material.Concrete
	end
	for _, x in { -11, 11 } do
		local facade = makePart(model, "FrontFacade", Vector3.new(7, 9, 0.7), center + Vector3.new(x, 5.5, -11.5), Color3.fromRGB(225, 226, 214))
		facade.Material = Enum.Material.Concrete
	end
	for _, x in { -5.2, 5.2 } do
		local window = makePart(model, "StorefrontWindow", Vector3.new(5, 6, 0.25), center + Vector3.new(x, 5, -11.9), Color3.fromRGB(90, 165, 175))
		window.Material = Enum.Material.Glass
		window.Transparency = 0.25
	end
	local header = makePart(model, "ProShopHeader", Vector3.new(18, 2.5, 0.5), center + Vector3.new(0, 8.2, -12), Color3.fromRGB(25, 90, 55))
	header.Material = Enum.Material.Slate
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = header
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "PRO SHOP"
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.Font = Enum.Font.GothamBold
	signText.TextScaled = true
	signText.Parent = signGui
	local counter = makePart(model, "SalesCounter", Vector3.new(10, 3, 2.5), center + Vector3.new(7, 2.8, 6), Color3.fromRGB(55, 78, 70))
	counter.Material = Enum.Material.Metal
	for index, x in { -8, 0, 8 } do
		local display = makePart(model, `MerchandiseDisplay{index}`, Vector3.new(4, 4, 2), center + Vector3.new(x, 3, 2), Color3.fromRGB(210, 205, 190))
		display.Material = Enum.Material.SmoothPlastic
		local merchandise = makePart(model, "GolfMerchandise", Vector3.new(2.8, 1.2, 1.4), center + Vector3.new(x, 5.4, 2), if index == 1 then Color3.fromRGB(55, 125, 75) elseif index == 2 then Color3.fromRGB(235, 190, 55) else Color3.fromRGB(65, 105, 175))
		merchandise.Material = Enum.Material.Fabric
	end
end

local function startProShopIncome(player)
	if proShopIncomeActive[player] then return end
	proShopIncomeActive[player] = true
	task.spawn(function()
		while proShopIncomeActive[player] and player.Parent do
			task.wait(Config.ProShop.RevenueInterval)
			local data = playerDataService:Get(player)
			if not proShopIncomeActive[player] or not data or not data.ProShopOwned then break end
			if cashService:AddCash(player, Config.ProShop.RevenuePerTick) then
				data.LifetimeRevenue += Config.ProShop.RevenuePerTick
				player:SetAttribute("LifetimeRevenue", data.LifetimeRevenue)
				BusinessService:RefreshProgression(player)
			end
		end
		proShopIncomeActive[player] = nil
	end)
end

function BusinessService:RefreshProgression(player)
	local data = playerDataService:Get(player)
	local plot = plotService:GetPlayerPlot(player)
	local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
	if not data or not content or not data.OwnedBuildings.DrivingRangeBay then return end
	if data.PuttingGreenOwned then
		createPuttingGreen(content, plot.Origin)
	else
		local unlocked = data.CustomersServed >= Config.PuttingGreen.UnlockCustomers and data.LifetimeRevenue >= Config.PuttingGreen.UnlockRevenue
		if unlocked and not content:FindFirstChild("PuttingGreenPurchasePad") then
		local pad = makePart(content, "PuttingGreenPurchasePad", Vector3.new(12, 1, 12), plot.Origin + Vector3.new(50, 1, 25), Color3.fromRGB(180, 120, 220))
		addPrompt(pad, `Build Putting Green - ${Config.PuttingGreen.Price}`, "Course Development", function(triggeringPlayer)
			self:PurchasePuttingGreen(triggeringPlayer, plot.Id)
		end)
		feedbackEvent:FireClient(player, "Putting Green unlocked!")
		end
	end
	if data.ProShopOwned then
		createProShop(content, plot.Origin)
		startProShopIncome(player)
	elseif data.BayCount >= Config.ProShop.UnlockBayCount and not content:FindFirstChild("ProShopPurchasePad") then
		local pad = makePart(content, "ProShopPurchasePad", Vector3.new(14, 1, 14), plot.Origin + Vector3.new(-48, 1, -4), Color3.fromRGB(225, 170, 55))
		addPrompt(pad, `Build Pro Shop - ${Config.ProShop.Price}`, "Retail Expansion", function(triggeringPlayer)
			self:PurchaseProShop(triggeringPlayer, plot.Id)
		end)
		feedbackEvent:FireClient(player, "Pro Shop expansion unlocked!")
	end
end

function BusinessService:PurchaseProShop(player, plotId)
	if purchaseLocks[player] then return end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local message
	if not data or not plotService:OwnsPlot(player, plotId) then message = "You can only expand your own property."
	elseif data.BayCount < Config.ProShop.UnlockBayCount then message = "Build the second bay to unlock the Pro Shop."
	elseif data.ProShopOwned then message = "You already own the Pro Shop."
	elseif not cashService:SpendCash(player, Config.ProShop.Price) then message = "Not enough cash for the Pro Shop."
	else
		data.ProShopOwned = true
		player:SetAttribute("ProShopOwned", true)
		local plot = plotService:GetPlayerPlot(player)
		local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
		local pad = content and content:FindFirstChild("ProShopPurchasePad")
		if pad then pad:Destroy() end
		if content then createProShop(content, plot.Origin) end
		startProShopIncome(player)
		message = `Pro Shop opened! It earns ${Config.ProShop.RevenuePerTick} every {Config.ProShop.RevenueInterval} seconds.`
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:PurchasePuttingGreen(player, plotId)
	if purchaseLocks[player] then return end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local unlocked = data and data.CustomersServed >= Config.PuttingGreen.UnlockCustomers and data.LifetimeRevenue >= Config.PuttingGreen.UnlockRevenue
	local message
	if not data or not plotService:OwnsPlot(player, plotId) or not unlocked then message = "Putting Green is not unlocked."
	elseif data.PuttingGreenOwned then message = "You already own the Putting Green."
	elseif not cashService:SpendCash(player, Config.PuttingGreen.Price) then message = "Not enough cash for the Putting Green."
	else
		data.PuttingGreenOwned = true
		player:SetAttribute("PuttingGreenOwned", true)
		local plot = plotService:GetPlayerPlot(player)
		local content = plot.Model:FindFirstChild("PlayerBusiness")
		local pad = content and content:FindFirstChild("PuttingGreenPurchasePad")
		if pad then pad:Destroy() end
		if content then createPuttingGreen(content, plot.Origin) end
		message = "Putting Green opened!"
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:PurchaseNextBay(player: Player, plotId: number)
	if purchaseLocks[player] then
		return
	end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local message
	local nextBayCount = data and data.BayCount + 1 or 0
	local price = Config.DrivingRange.BayUpgradePrices[nextBayCount]
	if not data or not plotService:OwnsPlot(player, plotId) then
		message = "You can only expand your own property."
	elseif not data.OwnedBuildings.DrivingRangeBay or data.BayCount >= Config.DrivingRange.MaxBayCount or not price then
		message = "This expansion is not available."
	elseif not cashService:SpendCash(player, price) then
		message = `Not enough cash for Bay {nextBayCount}.`
	else
		data.BayCount = nextBayCount
		player:SetAttribute("BayCount", nextBayCount)
		local plot = plotService:GetPlayerPlot(player)
		local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
		if content then
			local pad = content:FindFirstChild("NextBayUpgradePad")
			if pad then pad:Destroy() end
			createFacility(content, plot.Origin, data.BayCount)
		end
		self:RefreshProgression(player)
		if content and data.BayCount < Config.DrivingRange.MaxBayCount then
			local followingBayCount = data.BayCount + 1
			local followingPrice = Config.DrivingRange.BayUpgradePrices[followingBayCount]
			local upgradePad = makePart(content, "NextBayUpgradePad", Vector3.new(12, 1, 12), plot.Origin + Vector3.new(-20, 1, -28), Color3.fromRGB(70, 160, 220))
			addPrompt(upgradePad, `Build Bay {followingBayCount} - ${followingPrice}`, "Driving Range Expansion", function(triggeringPlayer)
				self:PurchaseNextBay(triggeringPlayer, plot.Id)
			end)
		end
		message = `Driving Range Bay {nextBayCount} opened!`
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:Purchase(player: Player, plotId: number, buildingId: string)
	if purchaseLocks[player] then return end
	purchaseLocks[player] = true
	local data = playerDataService:Get(player)
	local config = typeof(buildingId) == "string" and Config.Buildings[buildingId] or nil
	local message
	if not data or typeof(plotId) ~= "number" then message = "Invalid purchase."
	elseif not plotService:OwnsPlot(player, plotId) then message = "You can only buy on your own property."
	elseif not config then message = "Invalid building."
	elseif data.OwnedBuildings[buildingId] then message = "You already own this building."
	elseif not cashService:SpendCash(player, config.Price) then message = "Not enough cash."
	else
		data.OwnedBuildings[buildingId] = true
		data.BayCount = 1
		local plot = plotService:GetPlayerPlot(player)
		local content = plot and plot.Model:FindFirstChild("PlayerBusiness")
		if content then
			local pad = content:FindFirstChild("PurchasePad")
			if pad then pad:Destroy() end
			createFacility(content, plot.Origin, data.BayCount)
			self:_createManagementControls(player, content, plot)
		end
		customerService:StartForPlayer(player, buildingId)
		message = `Purchased {config.DisplayName}!`
	end
	feedbackEvent:FireClient(player, message)
	purchaseLocks[player] = nil
end

function BusinessService:SetupPlot(player: Player)
	local plot = plotService:GetPlayerPlot(player)
	local data = playerDataService:Get(player)
	if not plot or not data then return false end
	local content = Instance.new("Folder")
	content.Name = "PlayerBusiness"
	content.Parent = plot.Model
	createPropertyLayout(content, plot.Origin)
	if data.OwnedBuildings.DrivingRangeBay then
		createFacility(content, plot.Origin, data.BayCount)
		self:_createManagementControls(player, content, plot)
		customerService:StartForPlayer(player, "DrivingRangeBay")
		return true
	end
	local pad = makePart(content, "PurchasePad", Vector3.new(14, 1, 14), plot.Origin + Vector3.new(0, 1, 8), Color3.fromRGB(255, 200, 45))
	addPrompt(pad, "Buy Driving Range Bay - $250", "Golf Property", function(triggeringPlayer)
		self:Purchase(triggeringPlayer, plot.Id, "DrivingRangeBay")
	end)
	return true
end

function BusinessService:CleanupPlayer(player: Player)
	purchaseLocks[player] = nil
	proShopIncomeActive[player] = nil
end

return BusinessService
