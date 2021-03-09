import std.algorithm;
import std.range;
import std.conv;
import std.format;
import std.stdio;

import boilerplate;

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
}
