// import battletime;
import stats;
import unit;

import luad.all;
import boilerplate;

class Effect
{
	private
	{
	//	@Read void delegate(BattleTime) _recurring;
		@Read Stats delegate(Stats) _changeStats;
		@Read bool delegate(Unit) _changeTurn;
		@Read LuaState _lua;
	}

	this(Stats delegate(Stats) c2, bool delegate(Unit) c3)
	{
		_changeStats = c2;
		_changeTurn = c3;
		_lua = new LuaState;
	}
}
