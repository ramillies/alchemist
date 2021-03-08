import std.algorithm;
import std.array;
import std.range;
import std.json;

import boilerplate;
import luad.all;

class Place
{
	private
	{
		@Read size_t _x, _y;
		@Read string _name, _description;
		LuaState lua;
	}

	mixin(GenerateAll);

	this(size_t x, size_t y, string n, string d)
	{
		_x = x; _y = y; _name = n; _description = d;
		lua = new LuaState;
		lua.openLibs;
	}

	void newDay() { lua.doString(`place:newDay()`); }

	void luaPutInto(LuaTable obj)
	{
		obj["getX"] = delegate size_t(LuaTable t) { return this._x; };
		obj["getY"] = delegate size_t(LuaTable t) { return this._y; };
		obj["getName"] = delegate string(LuaTable t) { return this._name; };
		obj["setName"] = delegate void(LuaTable t, string x) { this._name = x; };
		obj["getDescription"] = delegate string(LuaTable t) { return this._description; };
		obj["setDescription"] = delegate void(LuaTable t, string x) { this._description = x; };
	}

	static Place fromJSON(size_t x, size_t y, JSONValue jv)
	{
		Place result = new Place(x, y, jv["name"].str, jv["description"].str);
		result.lua.doString(`place = { }`);
		result.luaPutInto(result.lua.get!LuaTable("place"));
		result.lua.doString(jv["script"].str);
		result.lua.doString(`place:init()`);
		return result;
	}
}
