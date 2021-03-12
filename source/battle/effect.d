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
		@Read @Write void delegate() _recurring;
		@Read @Write Stats delegate(Stats) _changeStats;
		@Read @Write bool delegate(Unit) _changeTurn;
		@Read LuaState _lua;
	}

	this(string n, AttackType t)
	{
		_name = n;
		_type = t;
		_lua = new LuaState;
	}

	
	mixin(GenerateAll);

	override Tuple!(double, "cooldown", double, "speedFactor") takeTurn()
	{
		return tuple!("cooldown", "speedFactor")(1., 1.);
	}
}
