function attackAll(position, friends, enemies)
	result = { }
	for k, v in pairs(enemies) do
		if v then table.insert(result, k-1) end
	end
	return result
end

function attackRanged(position, friends, enemies)
	result = { }
	for k, v in pairs(enemies) do
		if v then table.insert(result, { k-1 }) end
	end
	return result
end

function attackMelee(position, friends, enemies)
	function hitRow(row)
		local hittable = {}
		for k, v in pairs(row) do
			if enemies[v+1] then
				table.insert(hittable, v)
			end
		end
		if #hittable == 1 then
			return { hittable }
		else
			local myColumn = math.floor(position/2)
			local retval = { }
			for k, v in pairs(hittable) do
				local hisColumn = math.floor(3 - v/2)
				if math.abs(myColumn - hisColumn) <= 1 then
					table.insert(retval, { v })
				end
			end
			return retval
		end
	end

	if (position % 2 == 0 and not friends[2] and not friends[4] and not friends[6])
		or position % 2 == 1 then
		if not enemies[2] and not enemies[4] and not enemies[6] then
			return hitRow { 4, 2, 0 }
		else
			return hitRow { 5, 3, 1 }
		end
	else
		return {}
	end
end
