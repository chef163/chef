-- 🐾 Собирает мемного питомца из деталей. Смотрит в -Z, pivot — центр тела.

local PetBuilder = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local function addPart(model, props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = model
	return part
end

local function eyes(model, y, z, spread, size)
	for _, side in ipairs({ -1, 1 }) do
		addPart(model, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size,
			CFrame = CFrame.new(side * spread, y, z),
			Color = WHITE,
		})
		addPart(model, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size * 0.5,
			CFrame = CFrame.new(side * spread, y, z - size * 0.35),
			Color = BLACK,
		})
	end
end

function PetBuilder.build(pet)
	local model = Instance.new("Model")
	model.Name = pet.name
	local material = pet.material or Enum.Material.SmoothPlastic
	local style = pet.style or "plain"
	local body

	if style == "amogus" then
		body = addPart(model, { Size = Vector3.new(1.6, 2, 1.4), CFrame = CFrame.new(0, 0, 0), Color = pet.color, Material = material })
		addPart(model, { Size = Vector3.new(1.1, 0.55, 0.3), CFrame = CFrame.new(0, 0.35, -0.75), Color = Color3.fromRGB(150, 220, 255), Material = Enum.Material.Glass })
		addPart(model, { Size = Vector3.new(1.1, 1.2, 0.5), CFrame = CFrame.new(0, -0.1, 0.9), Color = pet.color, Material = material })
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, { Size = Vector3.new(0.6, 0.6, 0.8), CFrame = CFrame.new(side * 0.45, -1.1, 0), Color = pet.color, Material = material })
		end
	elseif style == "toilet" then
		body = addPart(model, { Size = Vector3.new(1.6, 1.2, 1.8), CFrame = CFrame.new(0, -0.6, 0), Color = pet.color, Material = material })
		addPart(model, { Size = Vector3.new(1.8, 1.8, 0.5), CFrame = CFrame.new(0, 0.2, 0.9), Color = pet.color, Material = material })
		addPart(model, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.2,
			CFrame = CFrame.new(0, 0.3, -0.1),
			Color = Color3.fromRGB(240, 200, 170),
		})
		eyes(model, 0.45, -0.6, 0.25, 0.3)
	else
		body = addPart(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(), Color = pet.color, Material = material })
		eyes(model, 0.3, -0.8, 0.35, 0.45)
		if style == "ears" then
			for _, side in ipairs({ -1, 1 }) do
				addPart(model, {
					Size = Vector3.new(0.5, 0.7, 0.3),
					CFrame = CFrame.new(side * 0.55, 1, 0) * CFrame.Angles(0, 0, math.rad(side * -20)),
					Color = pet.color,
					Material = material,
				})
			end
			addPart(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.35, CFrame = CFrame.new(0, -0.05, -0.95), Color = BLACK })
		end
	end

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()
	return model
end

return PetBuilder
