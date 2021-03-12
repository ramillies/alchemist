import std.algorithm, std.array, std.range;
import std.typecons;

import battletime;
import stats;
import unit;

import luad.all;
import boilerplate;

class Effect: TimeRegistrable
{
	private
	{
		@Read string _name;
		@Read AttackType _type;
		@Write void delegate() _recurring;
		@Write Stats delegate(Stats) _changeStats;
		@Write bool delegate(Unit) _changeTurn;
		@Read LuaState _lua;
	}

	this(string n, AttackType t)
	{
		_name = n;
		_type = t;
		_lua = new LuaState;
	}

	Stats applyStatsChange(Stats x) { return (_changeStats is null) ? x : _changeStats(x); }
	
	mixin(GenerateAll);

	override Tuple!(double, "cooldown", double, "speedFactor") takeTurn()
	{
		return tuple!("cooldown", "speedFactor")(1., 1.);
	}
}
