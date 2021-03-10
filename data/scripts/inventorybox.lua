function inventorybox(player, heading, msg, callback)
	local choices = {{ text = "Nothing", callback = function () callback("") end }}
	for item, count in pairs(player:getItems()) do
		if count > 0 then
			local name = Herbs[item].name
			local tile = Herbs[item].tilenumber
			table.insert(choices, {
				text = string.format("%s (you have %d)", name, count),
				tileset = "items",
				tilenumber = tile,
				callback = function () callback(item) end
			})
		end
	end
	choicebox(heading, msg, choices)
end
