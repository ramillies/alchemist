import std.algorithm, std.range, std.array;

import mainloop;
import reacttext;
import coolsprite;
import battletime;
import unit;
import player;

import boilerplate;
import luad.all;
import dsfml.graphics;

class BattleScreen: Screen
{
	private RenderWindow win;
	private bool nonlethal;
	private Player player;
	private Unit[] heroes, monsters;
	private void delegate(LuaTable) endBattleCallback;
	private BattleTime time;
	bool inInputState;

	this(Player p, Unit[] m, bool nl, void delegate(LuaTable) cb)
	{
		player = p;
		foreach(n; 0 .. 6)
		{
			auto index = m.countUntil!((x) => x.squadPosition == n);
			monsters ~= index == -1 ? cast(Unit) null : m[index];
		}
		foreach(n; 0 .. 6)
		{
			auto index = p.units.countUntil!((x) => x.squadPosition == n);
			heroes ~= index == -1 ? cast(Unit) null : p.units[index];
		}
		nonlethal = nl;
		endBattleCallback = cb;
		time = new BattleTime;
		inInputState = false;
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		const double marginX = .1*win.size.x, marginY = .2 * win.size.y;
		const double cellsize = .2*win.size.y;
		foreach(pos, unit; heroes)
		{
			if(unit is null) continue;
			unit.startBattle(time, heroes, monsters);
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			unit.position = Vector2f(
				marginX + cellsize*(pos % 2 + 1.5),
				marginY + cellsize*((pos/2) + .5)
			);

		}
		player.setBattlePosition(Vector2f(marginX + cellsize * .5, marginY + cellsize * 1.5));
		foreach(pos, unit; monsters)
		{
			if(unit is null) continue;
			unit.startBattle(time, monsters, heroes);
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			unit.position = Vector2f(
				win.size.x - marginX - cellsize*(pos % 2 + .5),
				win.size.y - marginY - cellsize*((pos/2) + 5)
			);
		}

		time.initTimes;
		time.nextTurn;
	}

	override void event(Event e)
	{
		if(!inInputState) return;
	}

	override void update(double dt)
	{
		if(time.cooldown > 0)
		{
			if(time.cooldown > dt)
				time.cooldown -= dt;
			else
			{
				time.cooldown = 0;
				if(!checkBattleEnd())
					time.nextTurn;
			}
		}
	}

	override void updateInactive(double dt) { }

	override void draw()
	{
		Vertex[] separators = [
			Vertex(Vector2f(0, .2*win.size.x), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(win.size.x, .2*win.size.x), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(0, .8*win.size.x), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(win.size.x, .8*win.size.x), Color.Red, Vector2f(0f, 0f))
		];
		win.draw(separators, PrimitiveType.Lines);

		heroes.each!((x) => x !is null && win.draw(x));
		monsters.each!((x) => x !is null && win.draw(x));
	}

	bool checkBattleEnd()
	{
		LuaState lua = new LuaState;
		lua.openLibs;
		LuaTable result = lua.loadString("return {}").call!LuaTable();
		if(monsters.filter!`a !is null`.all!`a.dead`)
			result["result"] = "victory";
		if(player.units.all!`a.dead || a.fled`)
			result["result"] = player.units.any!`a.fled` ? "flight" : "defeat";
		if(!result["result"].isNil)
		{
			player.endBattle(nonlethal);
			Mainloop.popScreen;
			endBattleCallback(result);
			return true;
		}
		return false;
	}

	override void finish() { }
}
