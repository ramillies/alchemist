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
	choicebox("Herbs!", string.format("There are %d %s here. Grab them?", self.herbs, Herbs[self.herbKey].name), {
		{ text = "Yes!", callback = function () self:grabHerbs(player) end },
		{ text = "Nope...", callback = function () end },
	} )
end

function place:grabHerbs(player)
	player:giveItems({ [self.herbKey] = self.herbs })
	local sep = ""
	local herbList = ""
	for k, v in pairs(player:getItems()) do
		if v > 0 then
			herbList = herbList .. sep .. string.format("%d × %s", v, Herbs[k].name)
			sep = ", "
		end
	end
	messagebox("New herbs!", string.format("You picked up %d %s here.\nNow you have %s.", self.herbs, Herbs[self.herbKey].name, herbList))
	self.herbs = 0
	self:updateDescription()
end

function place:updateDescription()
	self:setDescription(string.format("You can gather %d herbs here.", self.herbs, Time:day()))
end
