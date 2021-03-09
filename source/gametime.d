import std.algorithm;
import std.range;
import std.conv;
import std.format;
import std.stdio;

import boilerplate;
import util;
import luad.all;

class GameTime
{
	private
	{
		@Read double _days;
		void delegate (GameTime) [] callbacks;
	}

	mixin(GenerateAll);
	
	this() { _days = 0; }

	void advance(double dt)
	{
		int fullDays = to!int(_days+dt) - to!int(_days);
		_days += dt;
		foreach(callback; callbacks)
			fullDays.iota.each!((x) => callback(this));
	}

	void onNewDay(void delegate (GameTime) callback) { callbacks ~= callback; }

	string uiString()
	{
		int year, month, day;
		day = to!int(days);
		month = day/28; day -= 28*month;
		year = month/12; month -= 12*year;
		return format("Day %d, month %d, year %d", day+1, month+1, year+1);
	}

	void luaPutInto(LuaState lua)
	{
		lua.doString(`Time = {}`);
		auto obj = lua.get!LuaTable("Time");
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["day"] = delegate double (LuaTable t) { return string2ptr!GameTime(t.get!string("ptr")).days; };
		obj["advance"] = delegate void (LuaTable t, double dt) { string2ptr!GameTime(t.get!string("ptr")).advance(dt); };
	}
}
