import std.algorithm, std.range, std.array;
import std.stdio;
import std.datetime;
import std.format;

import mainloop;
import reacttext;
import coolsprite;
import gametime;
import unit;
import player;
import animation;
import resources;

import boilerplate;
import luad.all;
import dsfml.graphics;

class PartyScreen: Screen
{
	private ReactiveText[] texts;
	private RenderWindow win;
	private Player player;
	private GameTime time;
	private RectangleShape[] heroCells;
	private double marginX, marginY, cellsize;
	private int selected;

	this(Player p, GameTime t) { player = p; time = t; selected = -1; }

	Vector2f posToCoords(int pos)
	{
		auto left = marginX + cellsize*(pos % 2 + 1);
		auto top = marginY + cellsize*(pos/2);
		return Vector2f(left, top);
	}

	void putAtPos(Unit unit, int pos)
	{
		unit.setRelativeOrigin(Vector2f(.5f, .5f));
		auto coords = posToCoords(pos);
		unit.position = Vector2f(coords.x + cellsize/2, coords.y + cellsize/2);
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		marginX = .1*win.size.x;
		marginY = .2 * win.size.y;
		cellsize = .2*win.size.y;

		foreach(n; 0 .. 6)
		{
			RectangleShape heroCell = new RectangleShape(Vector2f(cellsize, cellsize));
			heroCell.fillColor = Color(0,0,0,0);
			heroCell.outlineThickness = -marginX/40;
			heroCell.outlineColor = Color.Red;
			heroCell.position = posToCoords(n);
			heroCells ~= heroCell;
		}

		texts = 3.iota.map!((x) => new ReactiveText).array;
		foreach(text; texts)
		{
			text.setFont(Fonts.text);
			text.setCharacterSize(30);
			text.setColor(Color.White);
			text.setRelativeOrigin(Vector2f(.5f, .5f));
			text.boxWidth = .15*win.size.x - 10;
		}

		texts[0].setCharacterSize(20);
		texts[0].positionCallback = () => Vector2f(.925*win.size.x, 0f);
		texts[0].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[0].stringCallback = delegate string()
		{
			auto systime = std.datetime.systime.Clock.currTime;
			return format("%02u:%02u", systime.hour, systime.minute);
		};

		texts[1].positionCallback = () => Vector2f(.925*win.size.x, .95*win.size.y);
		texts[1].stringCallback = () => time.uiString;

		with(texts[2])
		{
			setColor(Color(225, 188, 0));
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.925*win.size.x, .05*win.size.y - 5);
			stringCallback = () => format("%s", player.coins);
		}
	}

	override void event(Event e)
	{
		if(e.type == Event.EventType.Closed)
			Mainloop.quit;
		if(e.type == Event.EventType.KeyPressed)
		{
			if(e.key.code == Keyboard.Key.Escape || e.key.code == Keyboard.Key.P)
				Mainloop.popScreen;
		}
		if(e.type == Event.EventType.MouseButtonPressed)
		{
			int clicked = -1;
			foreach(n, rect; heroCells)
				if(rect.getGlobalBounds.contains(Mouse.getPosition(win)))
					clicked = cast(int) n;
			if(clicked != -1)
			{
				if(selected == -1)
					selected = clicked;
				else if(selected == clicked)
					selected = -1;
				else
				{
					auto selectedHero = player.units.find!((h) => h.squadPosition == selected);
					auto clickedHero = player.units.find!((h) => h.squadPosition == clicked);
					if(!selectedHero.empty && !clickedHero.empty)
					{
						selectedHero.front.squadPosition = clicked;
						clickedHero.front.squadPosition = selected;
						selected = -1;
					}
					else if(selectedHero.empty && !clickedHero.empty)
					{
						clickedHero.front.squadPosition = selected;
						selected = -1;
					}
					else if(!selectedHero.empty && clickedHero.empty)
					{
						selectedHero.front.squadPosition = clicked;
						selected = -1;
					}
				}
			}
		}
	}

	override void update(double dt)
	{
		foreach(hero; player.units)
			putAtPos(hero, hero.squadPosition);
		foreach(n, cell; heroCells)
		{
			cell.fillColor = cell.getGlobalBounds.contains(Mouse.getPosition(win)) ? Color(225, 188, 0, 80) : Color(0,0,0,0);
			heroCells[n].outlineColor = selected == n ? Color.Green : Color.Red;
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
		player.units.each!((x) => win.draw(x));
		win.draw(player);
	}

	override void finish() { }
}
