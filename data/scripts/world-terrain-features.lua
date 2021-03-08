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
			if featureAt(x, y) == "plain" and sum >= 4 then
				return "forest"
			elseif featureAt(x, y) == "forest" and sum < 2 then
				return "plain"
			else 
				return featureAt(x, y)
			end
		end
	}
}

makeMask(function (x, y) return terrainAt(x, y) == "grass" and mountainsAllowed(x, y) end)
distribute{ feature = "grass hill", number = math.ceil(land/40), exclusionRadius = 5 }
makeMask(function (x, y) return terrainAt(x, y) == "sand" and mountainsAllowed(x, y) end)
distribute{ feature = "cliff", number = math.ceil(land/30), exclusionRadius = 5 }

makeMask(settlementAllowed)
distribute{ feature = "city", number = math.ceil(land/250), exclusionRadius = 8 }
distribute{ feature = "village", number = math.ceil(land/60), exclusionRadius = 4 }
distribute{ feature = "castle", number = math.ceil(land/100), exclusionRadius = 4 }

makeRoads{ number = math.ceil(math.pow(land*(1/60+1/100+1/250), 2))/6 }

makeMask(function (x, y) return terrainAt(x, y) == "sand" and mountainsAllowed(x, y) and not roadAt(x, y) end)
distribute{ feature = "dune", number = math.ceil(land/60), exclusionRadius = 1 }
makeMask(function (x, y) return terrainAt(x, y) == "sand" and not roadAt(x, y) end)
distribute{ feature = "cactuses", number = math.ceil(land/10), exclusionRadius = 1 }
