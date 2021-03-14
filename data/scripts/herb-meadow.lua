function place:init()
	self.maxHerbs = math.random(7, 11)
	self.herbs = self.maxHerbs
	self:initSprites()
	local keys = {}
	for k, v in pairs(Herbs) do
		if loadstring(v.placeCondition)() then
			table.insert(keys, k)
		end
	end
	self.herbKey = keys[1 + math.floor(#keys * math.random())]
	self:setName(string.format("%s Meadow", Herbs[self.herbKey].name))
	self:updateDescription()
	for i = 1, math.floor(self.maxHerbs/2) do
		self:addSprite()
	end

end

function place:newDay()
	if self.herbs < self.maxHerbs and math.random() < 0.04 then
		self.herbs = self.herbs + 1
		if self.herbs % 2 == 1 then
			self:addSprite()
		end
		self:updateDescription()
	end
end

function place:enter(player)
	player:giveItems({ [self.herbKey] = self.herbs })
	messagebox("New herbs!", string.format("You picked up %d %s.", self.herbs, Herbs[self.herbKey].name, herbList))
	self.herbs = 0
	self:wipeSprites()
	self:updateDescription()
end

function place:updateDescription()
	self:setDescription(string.format("You can gather %d herbs here.", self.herbs, Time:day()))
end

function place:initSprites()
	self.availableSubPos = { }
	self.usedSprites = { }
	for k = 0, 2 do
		for l = 0, 2 do
			table.insert(self.availableSubPos, { k, l })
		end
	end
end

function place:addSprite()
	if #self.availableSubPos > 0 then
		local index = math.random(1, #self.availableSubPos)
		local spr = World:addPlaceSprite {
			position = { self:getX(), self:getY() },
			subposition = self.availableSubPos[index],
			tileset = "world tileset",
			tilenumber = Herbs[self.herbKey].worldTilenumber
		}
		if spr ~= "" then
			table.insert(self.usedSprites, spr)
			table.remove(self.availableSubPos, index)
		end
	end
end

function place:wipeSprites()
	for k, v in pairs(self.usedSprites) do
		World:removePlaceSprite(v)
	end
	place:initSprites()
end
