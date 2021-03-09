function place:init()
	self.herbs = 0
	self.maxHerbs = 10
	local keys = {}
	for k, v in pairs(Herbs) do
		if loadstring(v.placeCondition)() then
			table.insert(keys, k)
		end
	end
	self.herbKey = keys[1 + math.floor(#keys * math.random())]
	self:setName(string.format("%s Meadow", Herbs[self.herbKey].name))
	self:updateDescription()
end

function place:newDay()
	if self.herbs < self.maxHerbs and math.random() < 0.1 then
		self.herbs = self.herbs + 1
		self:updateDescription()
	end
end

function place:enter(player)
	print("Herb meadow entered.")
	player:giveItems({ [self.herbKey] = self.herbs })
	self.herbs = 0
	self:updateDescription()
end

function place:updateDescription()
	self:setDescription(string.format("You can gather %d herbs here.", self.herbs))
end
