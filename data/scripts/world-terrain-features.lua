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

makeMask(mountainsAllowed, true)
distribute{ feature = "mountains", number = 5, exclusionRadius = 14 }
fill{ feature = "mountains", number = math.ceil(land*.08), condition = mountainsAllowed }

makeMask(forestAllowed, true)
distribute{ feature = "forest", number = math.ceil(land*.3), exclusionRadius = 0 }
featureCellularAutomaton{
	iterations = 2,
	rules = {
		function (x, y)
			local sum = 0
			for k = -1,1 do
				for l = -1, 1 do
					if (k ~= 0 or l ~= 0) and featureAt(x+k, y+l) == "forest" then
						sum = sum + 1/(k*k+l*l)
					end
				end
			end
			if featureAt(x, y) == "plain" and sum >= 4 and forestAllowed(x, y) then
				return "forest"
			elseif featureAt(x, y) == "forest" and sum < 2 then
				return "plain"
			else 
				return featureAt(x, y)
			end
		end
	}
}

makeMask(function (x, y) return terrainAt(x, y) == "grass" and mountainsAllowed(x, y) end, true)
distribute{ feature = "grass hill", number = math.ceil(land/40), exclusionRadius = 3 }
makeMask(function (x, y) return terrainAt(x, y) == "sand" and mountainsAllowed(x, y) end, true)
distribute{ feature = "cliff", number = math.ceil(land/30), exclusionRadius = 3 }

makeMask(function (x, y)
	local sum = 0
	for k, v in pairs(adjacentTerrain(x,y)) do
		if v == "water" then sum = sum + 1 end
	end
	return settlementAllowed(x,y) and (water or math.random() < 0.33)
end, true)
distribute{ feature = "city", number = math.ceil(land/150), exclusionRadius = 8 }
makeMask(settlementAllowed, true)
distribute{ feature = "village", number = math.ceil(land/60), exclusionRadius = 4 }
distribute{ feature = "castle", number = math.ceil(land/120), exclusionRadius = 6 }

makeRoads{ roadFraction = 0.5 }

makeMask(function (x, y) return terrainAt(x, y) == "sand" and mountainsAllowed(x, y) and not roadAt(x, y) end, false)
distribute{ decoration = "dune", number = math.ceil(land/60), exclusionRadius = 1 }
makeMask(function (x, y) return terrainAt(x, y) == "sand" and not roadAt(x, y) end, false)
distribute{ decoration = "cactuses", number = math.ceil(land/10), exclusionRadius = 1 }
