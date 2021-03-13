dofile("data/scripts/deepcopy.lua")

function place:init()
	local monsterType = World:monsterTypeAt(self:getX(), self:getY())
	self.allowedMonsters = BasicMonsters[monsterType].monsters
	self.ingredient = BasicMonsters[monsterType].ingredient
	self.monsters = { { monster = self.allowedMonsters[math.random(1, #self.allowedMonsters)], position = 1 } }
	self.lootedCountdown = 0
	self:updateDescription()
end

function place:newDay()
	if self.lootedCountdown == 0 and #self.monsters < 3 and math.random() < 0.05 then
		table.insert(self.monsters,
			{
				monster = self.allowedMonsters[math.random(1, #self.allowedMonsters)],
				position = 1 + 2*#self.monsters
			}
		)
	end
	if self.lootedCountdown > 0 then
		self.lootedCountdown = self.lootedCountdown - 1
	end
end

function place:enter(player)
	if self.lootedCountdown == 0 then
		choicebox("Lair", string.format("You come closer to the monster lair. The locals are right to fear this place, because you can see %d × %s milling around.\n\nDo you want to fight them?", #self.monsters, Units[self.allowedMonsters[1]].name),
			{
				{ text = "To battle!", callback = function ()
					battlescreen(player, self.monsters, function (result)
						print("in battle callback")
						if result == "victory" then
							local give = 3*#self.monsters + math.random(1, 5)
							player:giveItems({ [self.ingredient] = give })
							self.lootedCountdown = math.random(336, 672)
							self.monsters = { }
							self:updateDescription()
							messagebox("Victory!", string.format("You defeated the vile monsters and searched the whole lair. After the looting is done and the place is ruined, you found that %d × %s will be useful to you.", give, Items[self.ingredient].name))
						else
							endgamescreen(player, PotionTable, "Defeat", "Sadly the death caught you in the midst of one of your many battles. The Potion of Youth will have to wait for another discoverer.")
						end
					end, false)
				end },
				{ text = "Let's swiftly be gone from this dangerous place." }
			}
		)
	end
end

function place:updateDescription()
	if self.lootedCountdown > 0 then
		self:setName("Ruined Lair")
		self:setDescription("This place was probably home to some kind of monsters, but now it is silent and empty.")
	else
		self:setName(string.format("%s Lair", Units[self.allowedMonsters[1]].name))
		self:setDescription("This is a lair of dangerous monsters. The locals do not dare to approach, but if you will dare it, perhaps you could help yourself to some ingredients?")
	end
end
