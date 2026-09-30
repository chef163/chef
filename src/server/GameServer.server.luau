-- 🧠 Серверная логика: +1 силы в секунду, удары по стенам, магазин кроссовок,
-- перерождения и сохранение прогресса.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local ShoeBuilder = require(Shared:WaitForChild("ShoeBuilder"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))

---------------------------------------------------------------------
-- Remote-события
---------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function newRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local HitRemote = newRemote("Hit")
local BuyRemote = newRemote("BuySneaker")
local BuyPetRemote = newRemote("BuyPet")
local RebirthRemote = newRemote("Rebirth")
local StateRemote = newRemote("State")
local NotifyRemote = newRemote("Notify")
remotes.Parent = ReplicatedStorage

MapBuilder.build()

---------------------------------------------------------------------
-- Сохранения
---------------------------------------------------------------------
local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[SneakerWall] DataStore недоступен, прогресс не сохранится:", result)
	end
end

local profiles = {} -- [Player] = { data, session, stats, loaded, canSave }

local function defaultData()
	return { power = 0, cash = 0, wins = 0, rebirths = 0, sneakers = {}, pets = {} }
end

local function loadData(player)
	local data = defaultData()
	if not store then
		return data, false
	end

	local ok, saved = pcall(function()
		return store:GetAsync("u_" .. player.UserId)
	end)
	if not ok then
		warn("[SneakerWall] Не удалось загрузить данные", player.Name, saved)
		return data, false
	end

	if type(saved) == "table" then
		data.power = tonumber(saved.power) or 0
		data.cash = tonumber(saved.cash) or 0
		data.wins = tonumber(saved.wins) or 0
		data.rebirths = tonumber(saved.rebirths) or 0
		if type(saved.sneakers) == "table" then
			for id, level in pairs(saved.sneakers) do
				if Config.getSneaker(id) and type(level) == "number" then
					data.sneakers[id] = level
				end
			end
		end
		if type(saved.pets) == "table" then
			for id, owned in pairs(saved.pets) do
				if Config.getPet(id) and owned == true then
					data.pets[id] = true
				end
			end
		end
	end
	return data, true
end

local function saveData(player, profile)
	if not store or not profile.canSave then
		return
	end
	local d = profile.data
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, {
			power = d.power,
			cash = d.cash,
			wins = d.wins,
			rebirths = d.rebirths,
			sneakers = d.sneakers,
			pets = d.pets,
		})
	end)
	if not ok then
		warn("[SneakerWall] Не удалось сохранить", player.Name, err)
	end
end

---------------------------------------------------------------------
-- Лидерборд и состояние
---------------------------------------------------------------------
local function setupLeaderstats(player, profile)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local function stat(className, name)
		local value = Instance.new(className)
		value.Name = name
		value.Parent = leaderstats
		return value
	end

	profile.stats = {
		power = stat("StringValue", "⚡ Сила"),
		cash = stat("StringValue", "💰 Деньги"),
		wins = stat("IntValue", "🏆 Победы"),
		rebirths = stat("IntValue", "🔁 Ребёрты"),
	}
	leaderstats.Parent = player
end

local function refreshLeaderstats(profile)
	local d, stats = profile.data, profile.stats
	stats.power.Value = Format.num(d.power)
	stats.cash.Value = Format.num(d.cash)
	stats.wins.Value = d.wins
	stats.rebirths.Value = d.rebirths
end

local function sendState(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local d, s = profile.data, profile.session
	refreshLeaderstats(profile)
	StateRemote:FireClient(player, {
		power = d.power,
		cash = d.cash,
		wins = d.wins,
		rebirths = d.rebirths,
		sneakers = d.sneakers,
		pets = d.pets,
		passes = profile.passes,
		broken = s.broken,
		currentHp = s.currentHp,
		gain = Config.getGain(d, profile.passes),
	})
end

local function notify(player, kind, payload)
	NotifyRemote:FireClient(player, kind, payload or {})
end

local function teleportToSpawn(player)
	local character = player.Character
	local spawn = MapBuilder.getSpawn()
	if character and spawn then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

---------------------------------------------------------------------
-- Кроссовки на ногах игрока (видны всем)
---------------------------------------------------------------------
local function bestSneaker(data)
	local best
	for _, sneaker in ipairs(Config.Sneakers) do
		if (data.sneakers[sneaker.id] or 0) > 0 then
			best = sneaker
		end
	end
	return best
end

local function equipShoes(player)
	local profile = profiles[player]
	local character = player.Character
	if not profile or not character then
		return
	end

	local old = character:FindFirstChild("SneakerFolder")
	if old then
		old:Destroy()
	end

	local sneaker = bestSneaker(profile.data)
	if not sneaker then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "SneakerFolder"
	folder.Parent = character

	for _, side in ipairs({ "Left", "Right" }) do
		local foot = character:FindFirstChild(side .. "Foot") or character:FindFirstChild(side .. " Leg")
		if foot and foot:IsA("BasePart") then
			local shoe = ShoeBuilder.build(sneaker, 0.9)
			shoe:PivotTo(foot.CFrame * CFrame.new(0, -foot.Size.Y / 2 - 0.05, 0))
			shoe.Parent = folder
			for _, part in ipairs(shoe:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.Massless = true
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = foot
					weld.Part1 = part
					weld.Parent = part
					part.Anchored = false
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Питомец: сервер только ставит атрибут, летающую модельку рисуют клиенты
---------------------------------------------------------------------
local function equipPet(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local pet = Config.getBestPet(profile.data.pets)
	player:SetAttribute("PetId", if pet then pet.id else nil)
end

---------------------------------------------------------------------
-- Game Pass'ы
---------------------------------------------------------------------
local function loadPasses(player, profile)
	for _, pass in ipairs(Config.GamePasses) do
		if pass.id and pass.id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				profile.passes[pass.key] = true
			end
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	local profile = profiles[player]
	if not purchased or not profile then
		return
	end
	for _, pass in ipairs(Config.GamePasses) do
		if pass.id == passId then
			profile.passes[pass.key] = true
			notify(player, "pass", { name = pass.name })
			sendState(player)
		end
	end
end)

---------------------------------------------------------------------
-- Вход / выход игроков
---------------------------------------------------------------------
local function onPlayerAdded(player)
	local profile = {
		data = defaultData(),
		session = { broken = 0, currentHp = nil, lastHit = 0 },
		passes = {},
		loaded = false,
		canSave = false,
	}
	profiles[player] = profile
	setupLeaderstats(player, profile)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.5)
		if profiles[player] == profile then
			equipShoes(player)
		end
	end)

	local data, canSave = loadData(player)
	loadPasses(player, profile)
	if profiles[player] ~= profile then
		return -- игрок успел выйти
	end
	profile.data = data
	profile.canSave = canSave
	profile.loaded = true

	if player.Character then
		equipShoes(player)
	end
	equipPet(player)
	sendState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player]
	profiles[player] = nil
	if profile and profile.loaded then
		saveData(player, profile)
	end
end)

game:BindToClose(function()
	local pending = 0
	for player, profile in pairs(profiles) do
		if profile.loaded then
			pending += 1
			task.spawn(function()
				saveData(player, profile)
				pending -= 1
			end)
		end
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end)

-- Автосохранение
task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVAL)
		for player, profile in pairs(profiles) do
			if profile.loaded then
				task.spawn(saveData, player, profile)
			end
		end
	end
end)

---------------------------------------------------------------------
-- +1 каждую секунду
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(Config.GAIN_INTERVAL)
		for player, profile in pairs(profiles) do
			if profile.loaded then
				profile.data.power += Config.getGain(profile.data, profile.passes)
				sendState(player)
			end
		end
	end
end)

---------------------------------------------------------------------
-- Удар по стене
---------------------------------------------------------------------
HitRemote.OnServerEvent:Connect(function(player, wallIndex)
	local profile = profiles[player]
	if not profile or not profile.loaded or typeof(wallIndex) ~= "number" then
		return
	end
	local d, s = profile.data, profile.session

	-- ломать можно только следующую по порядку стену
	if wallIndex ~= s.broken + 1 then
		return
	end
	local wallConfig = Config.Walls[wallIndex]
	local wall = MapBuilder.getWall(wallIndex)
	if not wallConfig or not wall then
		return
	end

	local now = os.clock()
	if now - s.lastHit < Config.HIT_COOLDOWN * 0.8 then
		return
	end
	s.lastHit = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local distance = math.abs(root.Position.Z - wall.Position.Z) - wall.Size.Z / 2
	if distance > Config.HIT_RANGE + 4 then
		return
	end

	local damage = math.max(1, math.floor(d.power))
	s.currentHp = (s.currentHp or wallConfig.hp) - damage

	if s.currentHp > 0 then
		notify(player, "hit", { wall = wallIndex, hp = s.currentHp, damage = damage })
		return
	end

	-- стена сломана!
	s.broken = wallIndex
	s.currentHp = nil
	local reward = wallConfig.reward * (if profile.passes.DoubleCash then 2 else 1)
	d.cash += reward
	notify(player, "break", { wall = wallIndex, reward = reward, damage = damage })

	if wallIndex >= #Config.Walls then
		d.wins += 1
		notify(player, "win", { wins = d.wins })
		sendState(player)
		task.delay(3, function()
			if profiles[player] ~= profile or s.broken < #Config.Walls then
				return
			end
			s.broken = 0
			s.currentHp = nil
			teleportToSpawn(player)
			sendState(player)
		end)
	else
		sendState(player)
	end
end)

---------------------------------------------------------------------
-- Покупка кроссовок (каждая покупка дороже предыдущей)
---------------------------------------------------------------------
BuyRemote.OnServerEvent:Connect(function(player, sneakerId)
	local profile = profiles[player]
	if not profile or not profile.loaded or typeof(sneakerId) ~= "string" then
		return
	end
	local sneaker = Config.getSneaker(sneakerId)
	if not sneaker then
		return
	end

	local d = profile.data
	local level = d.sneakers[sneakerId] or 0
	local price = Config.getPrice(sneaker, level)
	if d.cash < price then
		notify(player, "error", { text = "Не хватает денег! 💸 Нужно " .. Format.num(price) })
		return
	end

	d.cash -= price
	d.sneakers[sneakerId] = level + 1
	equipShoes(player)
	notify(player, "buy", { id = sneakerId, level = level + 1 })
	sendState(player)
end)

---------------------------------------------------------------------
-- Покупка питомцев (один раз, навсегда)
---------------------------------------------------------------------
BuyPetRemote.OnServerEvent:Connect(function(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded or typeof(petId) ~= "string" then
		return
	end
	local pet = Config.getPet(petId)
	local d = profile.data
	if not pet or d.pets[petId] then
		return
	end
	if d.cash < pet.price then
		notify(player, "error", { text = "Не хватает денег! 💸 Нужно " .. Format.num(pet.price) })
		return
	end

	d.cash -= pet.price
	d.pets[petId] = true
	equipPet(player)
	notify(player, "pet", { id = petId })
	sendState(player)
end)

---------------------------------------------------------------------
-- Перерождение: сброс силы, денег и кроссовок ради постоянного множителя
---------------------------------------------------------------------
RebirthRemote.OnServerEvent:Connect(function(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return
	end
	local d, s = profile.data, profile.session
	local cost = Config.getRebirthCost(d.rebirths)
	if d.cash < cost then
		notify(player, "error", { text = "Для ребёрта нужно 💰 " .. Format.num(cost) })
		return
	end

	d.rebirths += 1
	d.power = 0
	d.cash = 0
	d.sneakers = {} -- питомцы остаются
	s.broken = 0
	s.currentHp = nil

	equipShoes(player)
	teleportToSpawn(player)
	notify(player, "rebirth", { rebirths = d.rebirths })
	sendState(player)
end)

---------------------------------------------------------------------
-- 🏆 Глобальные таблицы лидеров на карте
---------------------------------------------------------------------
local nameCache = {}
local function getName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local result = if ok and name then name else "Игрок " .. tostring(userId)
	nameCache[userId] = result
	return result
end

local boardStores = {}
for _, key in ipairs({ "Wins", "Power" }) do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore("SneakerWall_Top" .. key)
	end)
	if ok then
		boardStores[key] = result
	end
end

local function boardValue(key, data)
	local value = if key == "Wins" then data.wins else data.power
	return math.floor(math.clamp(value, 0, 2 ^ 53))
end

local function updateBoard(key)
	local rows = MapBuilder.getBoardRows(key)
	local ordered = boardStores[key]
	if not rows then
		return
	end

	local ok = pcall(function()
		assert(ordered, "no store")
		for player, profile in pairs(profiles) do
			if profile.loaded and profile.canSave then
				ordered:SetAsync(tostring(player.UserId), boardValue(key, profile.data))
			end
		end
		local page = ordered:GetSortedAsync(false, Config.LEADERBOARD_SIZE):GetCurrentPage()
		for i = 1, Config.LEADERBOARD_SIZE do
			local entry = page[i]
			if entry then
				local medal = if i == 1 then "🥇" elseif i == 2 then "🥈" elseif i == 3 then "🥉" else "#" .. i
				local userId = tonumber(entry.key) or 0
				rows[i].Text = medal .. " " .. getName(userId) .. " — " .. Format.num(entry.value)
			else
				rows[i].Text = ""
			end
		end
	end)

	if not ok then
		-- В Studio без API Services показываем локальный топ текущего сервера
		local list = {}
		for player, profile in pairs(profiles) do
			if profile.loaded then
				table.insert(list, { name = player.Name, value = boardValue(key, profile.data) })
			end
		end
		table.sort(list, function(a, b)
			return a.value > b.value
		end)
		for i = 1, Config.LEADERBOARD_SIZE do
			local entry = list[i]
			rows[i].Text = if entry then "#" .. i .. " " .. entry.name .. " — " .. Format.num(entry.value) else ""
		end
		if #list < Config.LEADERBOARD_SIZE then
			rows[Config.LEADERBOARD_SIZE].Text = "(топ этого сервера)"
		end
	end
end

task.spawn(function()
	task.wait(5)
	while true do
		updateBoard("Wins")
		updateBoard("Power")
		task.wait(Config.LEADERBOARD_UPDATE)
	end
end)
