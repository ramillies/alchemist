function inventorybox(player, heading, msg, callback)
	local choices = {{ text = "Nothing", callback = function () callback("") end }}
	for item, count in pairs(player:getItems()) do
		if count > 0 then
			local name = Herbs[item].name
			local tile = Herbs[item].tilenumber
			local tileset = Herbs[item].tileset
			table.insert(choices, {
				text = string.format("%s (you have %d)", name, count),
				tileset = tileset,
				tilenumber = tile,
				callback = function () callback(item) end
			})
		end
	end
	choicebox(heading, msg, choices)
end
