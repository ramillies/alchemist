function table.deepcopy(x)
	result = { }
	for k, v in pairs(x) do
		if type(v) == table then
			result[k] = table.deepcopy(v)
		else
			result[k] = v
		end
	end
	return result
end
