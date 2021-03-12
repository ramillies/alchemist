import std.algorithm, std.range, std.array;

import mainloop;
import reacttext;
import coolsprite;
import battletime;
import unit;

import boilerplate;
import luad.all;
import dsfml.graphics;

class BattleScreen: Screen
{
	private RenderWindow win;
	private bool nonlethal;
	private Player player;
	private Unit[] monsters;
	private void delegate(LuaTable) endBattleCallback;
	private BattleTime time;
	bool inInputState;

	this(Player p, Unit[] m, bool nl, void delegate(LuaTable) cb)
	{
		player = p;
		monsters = m;
		nonlethal = nl;
		endBattleCallback = cb;
		time = new BattleTime;
		inInputState = false;
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		const double margin = .1*win.size.x;
		const double cellsize = .2*win.size.y;
		foreach(unit; player.units)
		{
			unit.saveCheckpoint;
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			unit.position = Vector2f(
				margin + cellsize*(unit.squadPosition % 2 + .5),
				cellsize*((unit.squadPosition/2) + 1.5)
			);

		}
		foreach(unit; monsters)
		{
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			unit.position = Vector2f(
				win.size.x - margin - cellsize*(unit.squadPosition % 2 + .5),
				win.size.y - cellsize*((unit.squadPosition/2) + 1.5)
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

		player.units.each!((x) => win.draw(x));
		monsters.each!((x) => win.draw(x));
	}

	override bool checkBattleEnd()
	{
		LuaState lua = new LuaState;
		lua.openLibs;
		LuaTable result = lua.loadString("return {}").call!LuaTable();
		if(monsters.all!`a.dead`)
			result["result"] = "victory";
		if(player.units.all!`a.dead || a.fled`)
			result["result"] = playr.units.any!`a.fled` ? "flee" : "defeat";
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
