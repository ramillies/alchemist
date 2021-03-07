function mountainsAllowed(x, y)
	for k, v in pairs(adjacentTerrain(x,y)) do
		if v == "water" then return false end
	end
	for k, v in pairs(diagonallyAdjacentTerrain(x,y)) do
		if v == "water" then return false end
	end
	return true
end

function forestAllowed(x, y)
	if terrainAt(x, y) == "grass" or terrainAt(x, y) == "snow" then
		return true
	else
		return false
	end
end

function settlementAllowed(x, y)
	if y == height-1 or terrainAt(x, y+1) == "water" then
		return false
	else
		return true
	end
end

land = width * height * landFraction

makeMask(mountainsAllowed)
distribute{ feature = "mountains", number = 5, exclusionRadius = 14 }
fill{ feature = "mountains", number = math.ceil(land*.08), condition = mountainsAllowed }

makeMask(forestAllowed)
distribute{ feature = "forest", number = 20, exclusionRadius = 4 }
fill{ feature = "forest", number = math.ceil(land*.2), condition = forestAllowed }

makeMask(function (x, y) return terrainAt(x, y) == "grass" and mountainsAllowed(x, y) end)
distribute{ feature = "grass hill", number = math.ceil(land/40), exclusionRadius = 5 }
makeMask(function (x, y) return terrainAt(x, y) == "sand" and mountainsAllowed(x, y) end)
distribute{ feature = "cliff", number = math.ceil(land/30), exclusionRadius = 5 }

makeMask(settlementAllowed)
distribute{ feature = "city", number = math.ceil(land/250), exclusionRadius = 8 }
distribute{ feature = "village", number = math.ceil(land/60), exclusionRadius = 4 }
distribute{ feature = "castle", number = math.ceil(land/100), exclusionRadius = 4 }
