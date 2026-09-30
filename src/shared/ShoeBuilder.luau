-- 👟 Собирает модельку кроссовка из деталей.
-- Используется для витрин на спавне и для кроссовок на ногах игрока.
-- Носок смотрит в -Z (как персонаж), точка опоры (pivot) — низ подошвы.

local ShoeBuilder = {}

local function addPart(model, className, size, position, color, material)
	local part = Instance.new(className)
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

function ShoeBuilder.build(sneaker, scale)
	local s = scale or 1
	local function v(x, y, z)
		return Vector3.new(x * s, y * s, z * s)
	end

	local main = sneaker.color
	local accent = sneaker.accent or Color3.new(1, 1, 1)
	local soleColor = sneaker.sole or Color3.new(1, 1, 1)
	local mainMaterial = sneaker.material
	local accentMaterial = sneaker.accentMaterial

	local model = Instance.new("Model")
	model.Name = sneaker.name

	local sole = addPart(model, "Part", v(1, 0.25, 1.6), v(0, 0.125, 0), soleColor)
	addPart(model, "Part", v(0.92, 0.6, 1), v(0, 0.55, 0.28), main, mainMaterial) -- верх
	addPart(model, "WedgePart", v(0.92, 0.45, 0.6), v(0, 0.475, -0.5), main, mainMaterial) -- носок
	addPart(model, "Part", v(0.04, 0.22, 0.9), v(0.47, 0.5, 0.05), accent, accentMaterial) -- полоска справа
	addPart(model, "Part", v(0.04, 0.22, 0.9), v(-0.47, 0.5, 0.05), accent, accentMaterial) -- полоска слева
	addPart(model, "Part", v(0.5, 0.06, 0.5), v(0, 0.88, 0.05), Color3.new(1, 1, 1)) -- шнурки
	addPart(model, "Part", v(0.5, 0.35, 0.12), v(0, 0.95, 0.75), accent, accentMaterial) -- задник

	model.PrimaryPart = sole
	model.WorldPivot = CFrame.new()
	return model
end

return ShoeBuilder
