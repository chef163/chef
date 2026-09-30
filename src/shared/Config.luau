-- ⚙️ Все настройки игры в одном месте.
-- Меняй цифры, названия, цвета и звуки здесь — остальные скрипты подхватят сами.

local Config = {}

---------------------------------------------------------------------
-- Основной баланс
---------------------------------------------------------------------
Config.BASE_GAIN = 1 -- +1 силы каждую секунду (суть режима «+1»)
Config.GAIN_INTERVAL = 1 -- раз во сколько секунд начисляется сила
Config.HIT_RANGE = 12 -- с какого расстояния (в студах) можно бить стену
Config.HIT_COOLDOWN = 0.12 -- минимальная пауза между ударами
Config.AUTO_HIT_INTERVAL = 0.25 -- скорость авто-удара
Config.PRICE_GROWTH = 1.55 -- во сколько раз дорожает кроссовок после каждой покупки
Config.REBIRTH_BONUS = 0.5 -- +50% к приросту силы за каждое перерождение
Config.REBIRTH_BASE_COST = 1e6 -- цена первого перерождения
Config.REBIRTH_COST_GROWTH = 5 -- во сколько раз дорожает каждое следующее перерождение

Config.DATASTORE_NAME = "SneakerWall_v1"
Config.AUTOSAVE_INTERVAL = 90

---------------------------------------------------------------------
-- Размеры карты
---------------------------------------------------------------------
Config.Map = {
	TrackWidth = 80, -- ширина дорожки
	SpawnDepth = 41, -- насколько спавн-зона уходит назад от центра
	FirstWallZ = -60, -- где стоит первая стена
	Spacing = 70, -- расстояние между стенами
	WallHeight = 40,
	WallThickness = 6,
	FinishLength = 60, -- длина финишной зоны после последней стены
}

---------------------------------------------------------------------
-- Стены: чем дальше, тем больше HP и награда
---------------------------------------------------------------------
Config.Walls = {
	{ name = "Стена Нуба", caption = "даже бабушка сломает", hp = 25, reward = 10, color = Color3.fromRGB(120, 200, 120) },
	{ name = "BRUH Стена", caption = "bruh... 💀", hp = 150, reward = 40, color = Color3.fromRGB(90, 170, 230) },
	{ name = "Сигма Стена", caption = "только для сигм 🗿", hp = 800, reward = 150, color = Color3.fromRGB(150, 110, 230) },
	{ name = "Стена из Огайо", caption = "only in Ohio 🌽", hp = 4000, reward = 600, color = Color3.fromRGB(230, 180, 60) },
	{ name = "Скибиди Стена", caption = "dop dop yes yes 🚽", hp = 20000, reward = 2500, color = Color3.fromRGB(230, 110, 70) },
	{ name = "Стена Ризза", caption = "+1000 rizz 😏", hp = 100000, reward = 10000, color = Color3.fromRGB(230, 80, 150) },
	{ name = "Амогус Стена", caption = "ඞ ты импостер?", hp = 500000, reward = 45000, color = Color3.fromRGB(220, 50, 50) },
	{ name = "Стена Чилл Гая", caption = "просто чилловый парень 🐶", hp = 2500000, reward = 200000, color = Color3.fromRGB(110, 90, 70) },
	{ name = "Стена Гигачада", caption = "ГИГАЧАД ОДОБРЯЕТ 💪", hp = 15000000, reward = 1000000, color = Color3.fromRGB(60, 60, 70) },
	{
		name = "ФИНАЛЬНАЯ СТЕНА +1",
		caption = "сломай — и ты легенда 🏆",
		hp = 100000000,
		reward = 5000000,
		color = Color3.fromRGB(255, 200, 40),
		material = Enum.Material.Neon,
	},
}

---------------------------------------------------------------------
-- Кроссовки (пародийные названия — настоящие бренды в Roblox могут снести за авторские права)
-- gain  — сколько силы в секунду добавляет КАЖДЫЙ уровень
-- price — стартовая цена; дальше каждая покупка дороже в PRICE_GROWTH раз
---------------------------------------------------------------------
Config.Sneakers = {
	{ id = "slippers", name = "Тапки Бабушки", price = 25, gain = 1, color = Color3.fromRGB(200, 90, 90), accent = Color3.fromRGB(255, 220, 220), sole = Color3.fromRGB(120, 60, 60) },
	{ id = "af1", name = "Air Farce 1", price = 150, gain = 3, color = Color3.fromRGB(245, 245, 245), accent = Color3.fromRGB(210, 210, 210) },
	{ id = "jordon", name = "Jordon 4 «Bred»", price = 750, gain = 10, color = Color3.fromRGB(30, 30, 30), accent = Color3.fromRGB(210, 30, 40) },
	{ id = "yeezus", name = "Yeezus Boost 350", price = 4000, gain = 35, color = Color3.fromRGB(215, 195, 160), accent = Color3.fromRGB(180, 160, 125), sole = Color3.fromRGB(235, 225, 205) },
	{ id = "dunk", name = "Dunk Low «Ohio»", price = 20000, gain = 120, color = Color3.fromRGB(60, 140, 70), accent = Color3.fromRGB(250, 210, 50) },
	{ id = "nb", name = "New Balanse 550", price = 100000, gain = 400, color = Color3.fromRGB(240, 240, 235), accent = Color3.fromRGB(30, 110, 60) },
	{ id = "balenci", name = "Balenci-Aga Triple S", price = 500000, gain = 1500, color = Color3.fromRGB(150, 150, 160), accent = Color3.fromRGB(90, 90, 100), sole = Color3.fromRGB(200, 200, 200) },
	{ id = "offwait", name = "Off-Wait «Sigma»", price = 2500000, gain = 5000, color = Color3.fromRGB(250, 250, 250), accent = Color3.fromRGB(255, 130, 0) },
	{ id = "airmag", name = "Air Mag «Back to Ohio»", price = 15000000, gain = 20000, color = Color3.fromRGB(170, 175, 185), accent = Color3.fromRGB(0, 200, 255), accentMaterial = Enum.Material.Neon },
	{ id = "gigachad", name = "Золотые Кроссы Гигачада", price = 100000000, gain = 80000, color = Color3.fromRGB(255, 200, 40), accent = Color3.fromRGB(255, 240, 150), material = Enum.Material.Foil, accentMaterial = Enum.Material.Neon },
}

---------------------------------------------------------------------
-- 🔊 Звуки
-- Найди мемы в Toolbox → Audio (Creator Store): "vine boom", "bruh", "cha ching",
-- "airhorn", "sad violin", "among us", "rizz", "sheesh" и т.п. → скопируй ID
-- и впиши "rbxassetid://ID". В любой пункт можно положить несколько звуков —
-- будет играть случайный. Пустая строка = звук выключен.
-- Сейчас стоят встроенные звуки Roblox, чтобы всё работало сразу.
---------------------------------------------------------------------
Config.Sounds = {
	Hit = { "rbxasset://sounds/swordslash.wav" }, -- удар по стене
	WallBreak = { "rbxasset://sounds/electronicpingshort.wav" }, -- сюда «Vine Boom»
	Buy = { "rbxasset://sounds/electronicpingshort.wav" }, -- сюда «Cha-ching»
	Win = { "rbxasset://sounds/electronicpingshort.wav" }, -- сюда «Airhorn» / «Wow»
	Rebirth = { "rbxasset://sounds/electronicpingshort.wav" }, -- сюда «Oh yeah»
	Error = { "rbxasset://sounds/uuhhh.mp3" }, -- сюда «Bruh»
	Memes = {}, -- случайный мем после сломанной стены: bruh, sus, sad violin, fart...
	Music = "", -- фоновая музыка (один ID)
}

-- Мемные надписи, которые вылетают на экран
Config.MemeTexts = {
	"BRUH 💀",
	"SHEESH 🥶",
	"W",
	"+1000 AURA ✨",
	"СИГМА 🗿",
	"GG EZ",
	"ONLY IN OHIO 🌽",
	"+RIZZ 😏",
	"SKIBIDI 🚽",
	"ЭТО ЖЕ ИМБА",
	"ИЗИ КАТКА",
	"АМОГУС ඞ",
	"ГИГАЧАД 💪",
	"ЧИЛЛ 🐶",
	"МЕГА ХАРОШ",
}

---------------------------------------------------------------------
-- Формулы (используются и сервером, и клиентом)
---------------------------------------------------------------------
local sneakerById = {}
for index, sneaker in ipairs(Config.Sneakers) do
	sneaker.index = index
	sneakerById[sneaker.id] = sneaker
end

function Config.getSneaker(id)
	return sneakerById[id]
end

function Config.getPrice(sneaker, level)
	return math.floor(sneaker.price * Config.PRICE_GROWTH ^ (level or 0))
end

function Config.getGain(ownedSneakers, rebirths)
	local gain = Config.BASE_GAIN
	for _, sneaker in ipairs(Config.Sneakers) do
		gain += sneaker.gain * ((ownedSneakers and ownedSneakers[sneaker.id]) or 0)
	end
	return gain * (1 + (rebirths or 0) * Config.REBIRTH_BONUS)
end

function Config.getRebirthCost(rebirths)
	return math.floor(Config.REBIRTH_BASE_COST * Config.REBIRTH_COST_GROWTH ^ (rebirths or 0))
end

return Config
