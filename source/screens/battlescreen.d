import std.algorithm, std.range, std.array;
import std.stdio;

import mainloop;
import reacttext;
import coolsprite;
import battletime;
import unit;
import player;
import animation;

import boilerplate;
import luad.all;
import dsfml.graphics;

class BattleScreen: Screen
{
	private RenderWindow win;
	private bool nonlethal;
	private Player player;
	private Unit[] heroes, monsters;
	private void delegate(string) endBattleCallback;
	private BattleTime time;
	Animation[] animations;
	bool inInputState;
	private RectangleShape[] heroCells, monsterCells;

	this(Player p, Unit[] m, bool nl, void delegate(string) cb)
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
			unit.startBattle(this, time, heroes, monsters);
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			auto left = marginX + cellsize*(pos % 2 + 1);
			auto top = marginY + cellsize*(pos/2);
			unit.position = Vector2f(
				left + .5*cellsize,
				top + .5*cellsize
			);
		}
		player.setBattlePosition(Vector2f(marginX + cellsize * .5, marginY + cellsize * 1.5));
		foreach(pos, unit; monsters)
		{
			if(unit is null) continue;
			unit.startBattle(this, time, monsters, heroes);
			unit.setRelativeOrigin(Vector2f(.5f, .5f));
			time.register(unit);
			unit.position = Vector2f(
				win.size.x - marginX - cellsize*(pos % 2 + .5),
				win.size.y - marginY - cellsize*((pos/2) + .5)
			);
		}
		foreach(n; 0 .. 6)
		{
			RectangleShape heroCell = new RectangleShape(Vector2f(cellsize, cellsize));
			heroCell.fillColor = Color(0,0,0,0);
			heroCell.position = Vector2f(marginX + cellsize*(n % 2 + 1), marginY + cellsize*(n/2));
			heroCells ~= heroCell;
			RectangleShape monsterCell = new RectangleShape(Vector2f(cellsize, cellsize));
			monsterCell.fillColor = Color(0,0,0,0);
			monsterCell.position = Vector2f(win.size.x - marginX - cellsize*(n % 2 + 1.), win.size.y - marginY - cellsize*((n/2) + 1.));
			monsterCells ~= monsterCell;
		}
	}

	override void event(Event e)
	{
		if(e.type == Event.EventType.Closed)
			Mainloop.quit;
		if(!inInputState) return;
	}

	override void update(double dt)
	{
		foreach(unit; heroes)
			if(unit !is null)
				unit.update;
		foreach(unit; monsters)
			if(unit !is null)
				unit.update;
		foreach(a; animations)
			a.updateAnimation(dt);
		while(animations.any!`a.animationFinished`)
			animations = animations.remove(animations.countUntil!`a.animationFinished`);
		
		if(!time.registered.empty)
		{
			foreach(n; 0..6)
			{
				heroCells[n].fillColor = (heroes[n] is time.registered[0]) ? Color(200, 0, 0, 80) : Color(0,0,0,0);
				monsterCells[n].fillColor = (monsters[n] is time.registered[0]) ? Color(200, 0, 0, 80) : Color(0,0,0,0);
			}
		}

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
		else
		{
			time.cooldown = 0;
			if(!checkBattleEnd())
				time.nextTurn;
		}
	}

	override void updateInactive(double dt) { }

	override void draw()
	{
		win.clear();
		Vertex[] separators = [
			Vertex(Vector2f(0, .2*win.size.y), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(win.size.x, .2*win.size.y), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(0, .8*win.size.y), Color.Red, Vector2f(0f, 0f)),
			Vertex(Vector2f(win.size.x, .8*win.size.y), Color.Red, Vector2f(0f, 0f))
		];
		win.draw(separators, PrimitiveType.Lines);

		heroCells.each!((x) => win.draw(x));
		monsterCells.each!((x) => win.draw(x));
		heroes.each!((x) => x !is null && win.draw(x));
		monsters.each!((x) => x !is null && win.draw(x));
		win.draw(player);
		foreach(a; animations)
			win.draw(a);
	}

	bool checkBattleEnd()
	{
		string result = "";
		if(monsters.filter!`a !is null`.all!`a.dead`)
			result = "victory";
		if(heroes.filter!`a !is null`.all!`a.dead || a.fled`)
			result = player.units.any!`a.fled` ? "flight" : "defeat";
		if(result != "")
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
