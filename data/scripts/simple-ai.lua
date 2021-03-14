function unit:init()
end

function unit:takeTurn()
	targets = self:attackTargets()
	if #targets == 0 then
		return { cooldown = 0.5, speedFactor = 0.5, actionDescription = "Wait" }
	end
	local bestIndex = 0
	local bestValue = { killed = 0, minHealth = math.huge }
	for index, group in pairs(targets) do
		local value = { killed = 0, minHealth = math.huge }
		for l, v in pairs(group) do 
			local try = enemies[v+1]:tryAttack(self.attack:getType())
			if try == "hit" then
				local hpLeft = enemies[v+1]:getHP() - self.attack:getStrength() * enemies[v+1]:getArmor()
				if hpLeft <= 0 then
					value.killed = value.killed + 1
				else
					value.minHealth = math.min(value.minHealth, hpLeft)
				end
			elseif try == "ward" then
				value.minHealth = math.min(value.minHealth, enemies[v+1]:getHP())
			end
		end
		if value.killed > bestValue.killed
			or (value.killed == bestValue.killed and value.minHealth < bestValue.minHealth) then
			bestIndex = index
			bestValue = value
		end
	end

	if bestIndex ~= 0 then
		for k, v in pairs(targets[bestIndex]) do
			enemies[v+1]:applyAttack(self.attack)
		end
		return {}
	else
		return { cooldown = 0.5, speedFactor = 0.5, actionDescription = "Wait" }
	end
end
