local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlotService = {}
local plots = {}
local playerDataService

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

local function addTree(parent, position, scale)
	local trunk = makePart(parent, "TreeTrunk", Vector3.new(2 * scale, 7 * scale, 2 * scale), position + Vector3.new(0, 3.5 * scale, 0), Color3.fromRGB(92, 62, 38))
	trunk.Material = Enum.Material.Wood
	local crown = makePart(parent, "TreeCrown", Vector3.new(7 * scale, 7 * scale, 7 * scale), position + Vector3.new(0, 8 * scale, 0), Color3.fromRGB(47, 116, 58))
	crown.Shape = Enum.PartType.Ball
	crown.Material = Enum.Material.Grass
end

local function addLabel(part, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlotLabel"
	gui.Size = UDim2.fromOffset(190, 38)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(25, 45, 25)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
	return label
end

local function addLamp(parent, position)
	local pole = makePart(parent, "PathLamp", Vector3.new(0.4, 7, 0.4), position + Vector3.new(0, 3.8, 0), Color3.fromRGB(45, 52, 50))
	pole.Material = Enum.Material.Metal
	local light = makePart(parent, "PathLampGlow", Vector3.new(1.2, 0.5, 1.2), position + Vector3.new(0, 7.2, 0), Color3.fromRGB(255, 224, 155))
	light.Material = Enum.Material.Neon
	local pointLight = Instance.new("PointLight")
	pointLight.Color = light.Color
	pointLight.Brightness = 1.2
	pointLight.Range = 16
	pointLight.Parent = light
end

local function addFlowerBed(parent, position, size)
	local soil = makePart(parent, "FlowerBed", size, position + Vector3.new(0, 0.7, 0), Color3.fromRGB(82, 58, 40))
	soil.Material = Enum.Material.Ground
	for x = -size.X / 2 + 2, size.X / 2 - 2, 3 do
		local flower = makePart(parent, "Flower", Vector3.new(1.2, 1.2, 1.2), position + Vector3.new(x, 1.5, 0), if math.floor(x) % 2 == 0 then Color3.fromRGB(245, 205, 75) else Color3.fromRGB(235, 235, 220))
		flower.Shape = Enum.PartType.Ball
		flower.Material = Enum.Material.Grass
	end
end

local function createWorldInfrastructure(parent)
	local world = Instance.new("Model")
	world.Name = "GolfResortInfrastructure"
	world.Parent = parent
	local frontRoad = makePart(world, "ResortBoulevard", Vector3.new(310, 0.35, 18), Vector3.new(0, 0.42, -105), Color3.fromRGB(54, 59, 60))
	frontRoad.Material = Enum.Material.Asphalt
	local centerRoad = makePart(world, "CentralAccessRoad", Vector3.new(12, 0.35, 410), Vector3.new(0, 0.42, 95), Color3.fromRGB(54, 59, 60))
	centerRoad.Material = Enum.Material.Asphalt
	local middleRoad = makePart(world, "MiddleBoulevard", Vector3.new(310, 0.35, 10), Vector3.new(0, 0.42, 100), Color3.fromRGB(54, 59, 60))
	middleRoad.Material = Enum.Material.Asphalt
	for x = -145, 145, 12 do
		local marking = makePart(world, "BoulevardMarking", Vector3.new(6, 0.05, 0.3), Vector3.new(x, 0.62, -105), Color3.fromRGB(235, 220, 150))
		marking.Material = Enum.Material.SmoothPlastic
	end
	for z = -95, 295, 14 do
		local marking = makePart(world, "AccessRoadMarking", Vector3.new(0.25, 0.05, 7), Vector3.new(0, 0.62, z), Color3.fromRGB(235, 220, 150))
		marking.Material = Enum.Material.SmoothPlastic
	end
	for x = -145, 145, 12 do
		local marking = makePart(world, "MiddleRoadMarking", Vector3.new(6, 0.05, 0.3), Vector3.new(x, 0.62, 100), Color3.fromRGB(235, 220, 150))
		marking.Material = Enum.Material.SmoothPlastic
	end
	for _, z in { -115, -95 } do
		local curb = makePart(world, "BoulevardCurb", Vector3.new(310, 0.55, 0.8), Vector3.new(0, 0.62, z), Color3.fromRGB(194, 190, 178))
		curb.Material = Enum.Material.Concrete
	end
end

local function configureLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 10.5
	Lighting.Brightness = 2.4
	Lighting.ExposureCompensation = 0.05
	Lighting.Ambient = Color3.fromRGB(105, 115, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(138, 150, 132)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.7
	Lighting.ShadowSoftness = 0.35
	for _, name in { "GolfEmpireAtmosphere", "GolfEmpireColor", "GolfEmpireBloom", "GolfEmpireSunRays" } do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GolfEmpireAtmosphere"
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(205, 225, 235)
	atmosphere.Decay = Color3.fromRGB(105, 125, 105)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting
	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "GolfEmpireColor"
	color.Brightness = 0.02
	color.Contrast = 0.08
	color.Saturation = 0.08
	color.TintColor = Color3.fromRGB(248, 252, 240)
	color.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "GolfEmpireBloom"
	bloom.Intensity = 0.18
	bloom.Size = 24
	bloom.Threshold = 1.8
	bloom.Parent = Lighting
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "GolfEmpireSunRays"
	sunRays.Intensity = 0.035
	sunRays.Spread = 0.75
	sunRays.Parent = Lighting
end

function PlotService:Init(dataService)
	playerDataService = dataService
	local old = workspace:FindFirstChild("GolfEmpirePlots")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "GolfEmpirePlots"
	folder.Parent = workspace
	configureLighting()
	createWorldInfrastructure(folder)

	for id = 1, Config.Plots.Count do
		local model = Instance.new("Model")
		model.Name = `Plot{id}`
		model.Parent = folder
		local column = (id - 1) % 2
		local row = math.floor((id - 1) / 2)
		local origin = Vector3.new(column * Config.Plots.Spacing - Config.Plots.Spacing / 2, 0, row * Config.Plots.RowSpacing)
		local ground = makePart(model, "Ground", Config.Plots.Size, origin, Color3.fromRGB(80 + id * 8, 145, 75))
		ground.Material = Enum.Material.Grass
		for _, edge in {
			{ Vector3.new(0.7, 0.5, 190), Vector3.new(-69.5, 0.62, 0) },
			{ Vector3.new(0.7, 0.5, 190), Vector3.new(69.5, 0.62, 0) },
		} do
			local curb = makePart(model, "PropertyCurb", edge[1], origin + edge[2], Color3.fromRGB(194, 190, 178))
			curb.Material = Enum.Material.Concrete
		end
		for _, x in { -38, 38 } do
			local curb = makePart(model, "FrontPropertyCurb", Vector3.new(64, 0.5, 0.7), origin + Vector3.new(x, 0.62, -94.5), Color3.fromRGB(194, 190, 178))
			curb.Material = Enum.Material.Concrete
		end
		local path = makePart(model, "EntryPath", Vector3.new(10, 0.25, 88), origin + Vector3.new(0, 0.65, -45), Color3.fromRGB(205, 194, 165))
		path.Material = Enum.Material.Cobblestone
		local plaza = makePart(model, "ArrivalPlaza", Vector3.new(28, 0.22, 22), origin + Vector3.new(0, 0.67, -28), Color3.fromRGB(190, 185, 170))
		plaza.Material = Enum.Material.Pavement
		local crossPath = makePart(model, "FacilityCrossPath", Vector3.new(104, 0.2, 7), origin + Vector3.new(0, 0.68, -18), Color3.fromRGB(205, 194, 165))
		crossPath.Material = Enum.Material.Cobblestone
		local parking = makePart(model, "GuestParking", Vector3.new(46, 0.2, 30), origin + Vector3.new(-42, 0.66, -65), Color3.fromRGB(62, 67, 68))
		parking.Material = Enum.Material.Asphalt
		for x = -60, -24, 9 do
			local stripe = makePart(model, "ParkingStripe", Vector3.new(0.25, 0.05, 11), origin + Vector3.new(x, 0.8, -65), Color3.fromRGB(235, 225, 180))
			stripe.Material = Enum.Material.SmoothPlastic
		end
		local cartPad = makePart(model, "GolfCartParking", Vector3.new(32, 0.2, 22), origin + Vector3.new(45, 0.66, -68), Color3.fromRGB(105, 110, 102))
		cartPad.Material = Enum.Material.Pavement
		for x = 34, 56, 11 do
			local stripe = makePart(model, "CartParkingStripe", Vector3.new(0.2, 0.05, 14), origin + Vector3.new(x, 0.8, -68), Color3.fromRGB(235, 225, 180))
			stripe.Material = Enum.Material.SmoothPlastic
		end
		for _, offset in { Vector3.new(-15, 0, -40), Vector3.new(15, 0, -40), Vector3.new(-15, 0, -16), Vector3.new(15, 0, -16) } do
			addLamp(model, origin + offset)
		end
		addFlowerBed(model, origin + Vector3.new(-19, 0, -87), Vector3.new(18, 0.5, 5))
		addFlowerBed(model, origin + Vector3.new(19, 0, -87), Vector3.new(18, 0.5, 5))
		for _, offset in { Vector3.new(-64, 0.5, -87), Vector3.new(64, 0.5, -87), Vector3.new(-64, 0.5, 87), Vector3.new(64, 0.5, 87) } do
			addTree(model, origin + offset, 0.8)
		end
		for x = -60, 60, 10 do
			local shrub = makePart(model, "BoundaryShrub", Vector3.new(5, 2.5, 3), origin + Vector3.new(x, 1.7, 90), Color3.fromRGB(45, 125, 58))
			shrub.Shape = Enum.PartType.Ball
			shrub.Material = Enum.Material.Grass
		end
		for _, x in { -7, 7 } do
			local pillar = makePart(model, "EntrancePillar", Vector3.new(1.4, 7, 1.4), origin + Vector3.new(x, 4, -88), Color3.fromRGB(218, 214, 198))
			pillar.Material = Enum.Material.Concrete
		end
		local sign = makePart(model, "Sign", Vector3.new(15, 4.5, 1), origin + Vector3.new(0, 5, -88), Color3.fromRGB(28, 82, 52))
		sign.Material = Enum.Material.Slate
		local cap = makePart(model, "EntranceSignCap", Vector3.new(17, 0.45, 1.5), origin + Vector3.new(0, 7.5, -88), Color3.fromRGB(40, 48, 46))
		cap.Material = Enum.Material.Metal
		local label = addLabel(sign, `Plot {id} - Available`)
		plots[id] = { Id = id, Model = model, Ground = ground, Origin = origin, Owner = nil, Label = label }
	end
end

function PlotService:AssignPlot(player: Player)
	local data = playerDataService:Get(player)
	if not data then
		return nil
	end
	for _, plot in ipairs(plots) do
		if not plot.Owner then
			plot.Owner = player
			data.PlotId = plot.Id
			plot.Label.Text = `{player.DisplayName}'s Golf Property`
			return plot
		end
	end
	return nil
end

function PlotService:GetPlayerPlot(player: Player)
	local data = playerDataService:Get(player)
	local plot = data and data.PlotId and plots[data.PlotId]
	return if plot and plot.Owner == player then plot else nil
end

function PlotService:OwnsPlot(player: Player, plotId: number): boolean
	local plot = plots[plotId]
	return plot ~= nil and plot.Owner == player
end

function PlotService:ReleasePlot(player: Player)
	local plot = self:GetPlayerPlot(player)
	if not plot then
		return
	end
	plot.Owner = nil
	plot.Label.Text = `Plot {plot.Id} - Available`
	local content = plot.Model:FindFirstChild("PlayerBusiness")
	if content then
		content:Destroy()
	end
	local data = playerDataService:Get(player)
	if data then
		data.PlotId = nil
	end
end

return PlotService
