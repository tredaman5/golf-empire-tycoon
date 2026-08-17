local Config = {}

Config.StartingCash = 500

Config.DataStore = {
	Name = "GolfEmpirePlayerData_v1",
	StudioName = "GolfEmpirePlayerData_Studio_v1",
	KeyPrefix = "Player_",
	SchemaVersion = 4,
	RetryCount = 3,
	RetryDelay = 2,
	AutosaveInterval = 60,
	EnableInStudio = false,
}

Config.Plots = {
	Count = 4,
	Size = Vector3.new(140, 1, 190),
	Spacing = 150,
	RowSpacing = 200,
}

Config.Buildings = {
	DrivingRangeBay = {
		DisplayName = "Driving Range Bay",
		Price = 250,
		CustomerPayment = 25,
	},
}

Config.DrivingRange = {
	BayUpgradePrices = {
		[2] = 750,
		[3] = 1500,
		[4] = 2500,
	},
	MaxBayCount = 4,
	ArrivalCapacityBoostPerBay = 0.75,
	DefaultPricingStrategy = "Standard",
	PricingOrder = { "Value", "Standard", "Premium" },
	PricingStrategies = {
		Value = { CustomerPayment = 20, SpawnInterval = 6 },
		Standard = { CustomerPayment = 25, SpawnInterval = 8 },
		Premium = { CustomerPayment = 40, SpawnInterval = 13 },
	},
}

Config.PuttingGreen = {
	Price = 1000,
	UnlockCustomers = 25,
	UnlockRevenue = 750,
	CustomerPayment = 35,
	ServiceDuration = 8,
	VisitEvery = 3,
}

Config.ProShop = {
	Price = 1200,
	UnlockBayCount = 2,
	RevenuePerTick = 30,
	RevenueInterval = 12,
}

Config.Customers = {
	SpawnInterval = 8,
	ServiceDuration = 6,
	WalkSpeed = 12,
	MaxQueueSize = 6,
	MaxPuttingQueueSize = 3,
}

return Config
