function place:init()
	self.herbs = 0
	self.maxHerbs = 10
	self:setDescription(string.format("You can gather %d herbs here.", self.herbs))
end

function place:newDay()
	if self.herbs < self.maxHerbs and math.random() < 0.1 then
		self.herbs = self.herbs + 1
		self:setDescription(string.format("You can gather %d herbs here.", self.herbs))
	end
end
