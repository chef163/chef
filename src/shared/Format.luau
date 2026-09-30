-- Красивые числа: 1500 -> 1.5K, 2300000 -> 2.3M

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.num(value)
	local n = tonumber(value) or 0
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)

	if n < 1000 then
		return sign .. tostring(math.floor(n))
	end

	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end

	local text
	if n < 10 then
		text = string.format("%.2f", n)
	elseif n < 100 then
		text = string.format("%.1f", n)
	else
		text = string.format("%d", math.floor(n))
	end

	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end

	return sign .. text .. SUFFIXES[i]
end

return Format
