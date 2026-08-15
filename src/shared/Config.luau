local Config = {}

Config.StartingCash = 500

Config.DataStore = {
	Name = "GolfEmpirePlayerData_v1",
	StudioName = "GolfEmpirePlayerData_Studio_v1",
	KeyPrefix = "Player_",
	SchemaVersion = 2,
	RetryCount = 3,
	RetryDelay = 2,
	AutosaveInterval = 60,
	EnableInStudio = true,
}

Config.Plots = {
	Count = 4,
	Size = Vector3.new(90, 1, 70),
	Spacing = 110,
}

Config.Buildings = {
	DrivingRangeBay = {
		DisplayName = "Driving Range Bay",
		Price = 250,
		CustomerPayment = 25,
	},
}

Config.DrivingRange = {
	SecondBayPrice = 750,
	MaxBayCount = 2,
	DefaultPricingStrategy = "Standard",
	PricingOrder = { "Value", "Standard", "Premium" },
	PricingStrategies = {
		Value = { CustomerPayment = 20, SpawnInterval = 6 },
		Standard = { CustomerPayment = 25, SpawnInterval = 8 },
		Premium = { CustomerPayment = 40, SpawnInterval = 13 },
	},
}

Config.Customers = {
	SpawnInterval = 8,
	ServiceDuration = 6,
	WalkSpeed = 12,
	MaxQueueSize = 3,
}

return Config
