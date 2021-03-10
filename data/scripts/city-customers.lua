customerTable = {
	{
		name = "Random customer guy",
		appear = function(city)
			return #city.customers == 0 and math.random() < 0.1
		end,
		init = function (self)
			local keys = { }
			for k, v in pairs(Herbs) do
				table.insert(keys, k)
			end
			self.want = keys[math.random(1, #keys)]
			print(string.format("Making a random customer guy. He wants a %s", self.want))
		end,
		talk = function (self, player)
			choicebox("Random customer guy",
				string.format("Hey, I want a %s. Do you have any?", Herbs[self.want].name),
				{
					{ text = "Yeah, I can give you some", callback = function ()
						inventorybox(player, "Random customer guy", "This is your inventory. What you will give him?", function (x) return self:check(player, x) end)
					end },
					{ text = "No way." }
				}
			)
		end,
		check = function (self, player, given)
			self.goAway = true
			if given == self.want then
				player:giveCoins(100)
				player:giveItems({ [self.want] = -1 })
				messagebox("Great!", "Here, take 100 coins!")
			elseif given == "" then
				self.goAway = false
			else
				messagebox("You Idiot!", string.format("You call yourself an alchemist and you can't recognize a %s? I can see that it is a %s! Now go away!", Herbs[self.want].name, Herbs[given].name))
			end
		end
	}
}
