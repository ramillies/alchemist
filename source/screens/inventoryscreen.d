import std.range;
import std.random;
import std.algorithm;
import std.array;
import std.stdio;
import std.format;
import std.math;
import std.conv;
import std.datetime.systime;

import mainloop;
import resources;
import tilemap;
import world;
import water;
import settings;
import player;
import place;
import reacttext;
import gametime;
import messagebox;
import choicebox;

import dsfml.graphics;

class InventoryScreen: Screen
{
	private ReactiveText[] texts;
	private Player player;
	private GameTime time;
	private int cellsize;
	private RectangleShape[] boxes;

	private RenderWindow win;

	this(Player p, GameTime t)
	{
		player = p;
		time = t;
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		cellsize = 96 * win.size.y / 1080;
		texts = 15.iota.map!((x) => new ReactiveText).array;
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

		texts[2].setFont(Fonts.heading);
		texts[2].setCharacterSize(35);
		texts[2].setRelativeOrigin(Vector2f(.5f, 1f));
		texts[2].setStyle(Text.Style.Bold);
		texts[2].positionCallback = () => Vector2f(.925*win.size.x, .35*win.size.y);
		texts[2].stringCallback = () => "Potion of Whatever";

		texts[3].positionCallback = () => Vector2f(.925*win.size.x, .37*win.size.y);
		texts[3].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[3].setCharacterSize(25);
		texts[3].stringCallback = () => "Description, blah blah blah.";

		with(texts[4])
		{
			setColor(Color(225, 188, 0));
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.925*win.size.x, .05*win.size.y - 5);
			stringCallback = () => format("%s", player.coins);
		}

		foreach(n; 5 .. 15)
			with(texts[n])
			{
				boxWidth = 0;
				setFont(Fonts.heading);
				setCharacterSize(70*win.size.y/1080);
				setColor(Color.Red);
				if(n < 11) setRelativeOrigin(Vector2f(.5f, 1f));
				else setCharacterSize(6*cellsize/5);
				setString(["Herbs", "Ingredients", "Potions", "Good", "Evil", "Combine", "I", "II", "III", "IV"][n-5]);
			}
		texts[5].positionCallback = () => Vector2f(.425*win.size.x, .7*cellsize);
		texts[6].positionCallback = () => Vector2f(.425*win.size.x, 2.45*cellsize);
		texts[7].positionCallback = () => Vector2f(.425*win.size.x, 4.2*cellsize);
		texts[8].positionCallback = () => Vector2f(.25*.85*win.size.x, 4.4*cellsize);
		texts[8].setCharacterSize(50*win.size.y/1080);
		texts[9].positionCallback = () => Vector2f(.75*.85*win.size.x, 4.4*cellsize);
		texts[9].setCharacterSize(50*win.size.y/1080);
		texts[10].position = Vector2f(.925*win.size.x, .90 * win.size.y);
		foreach(n; 11 .. 15)
			texts[n].position = Vector2f(.425*win.size.x, (5.5 + [0, 2.1, 3.7, 4.8][n - 11])*cellsize);

		void makeCellAt(float x, float y)
		{
			auto r = new RectangleShape(Vector2f(cellsize, cellsize));
			r.outlineThickness = -3;
			r.outlineColor = Color.Red;
			r.fillColor = Color(0, 0, 0, 0);
			r.position = Vector2f(x, y);
			boxes ~= r;
		}
		// Boxes for herbs
		foreach(n; 0 .. 6)
			makeCellAt(.425*win.size.x + (n-3)*cellsize, .8*cellsize);
		// Boxes for ingredients (monster parts)
		foreach(n; 0 .. 12)
			makeCellAt(.425*win.size.x + (n-6)*cellsize, 2.6*cellsize);
		// Boxes for level 1--3 good potions
		foreach(k; [ 0, 1, 2.1, 3.1, 4.2])
			foreach(n; 0 .. 6)
				makeCellAt(.25*.85*win.size.x + (n-3)*cellsize, (4.5+k)*cellsize);
		// Level 4 good potions
		foreach(n; 0 .. 3)
			makeCellAt(.25*.85*win.size.x + n*cellsize, (4.5 + 5.3)*cellsize);
		// Same for evil potions
		foreach(k; [ 0, 1, 2.1, 3.1, 4.2])
			foreach(n; 0 .. 6)
				makeCellAt(.75*.85*win.size.x + (n-3)*cellsize, (4.5+k)*cellsize);
		foreach(n; 0 .. 3)
			makeCellAt(.75*.85*win.size.x + (n-3)*cellsize, (4.5 + 5.3)*cellsize);
	}

	override void event(Event e)
	{
		if(e.type == e.EventType.Closed)
			Mainloop.quit;
		if(e.type == Event.EventType.KeyPressed)
		{
			if(e.key.code == Keyboard.Key.Escape)
				Mainloop.popScreen;
		}
	}

	override void update(double dt)
	{
		texts.each!((t) => t.update);
	}

	override void updateInactive(double dt)
	{
		texts[0].update;
		texts[1].update;
		texts[5].update;
	}

	override void draw()
	{
		win.clear();
		texts.each!((t) => win.draw(t));
		boxes.each!((t) => win.draw(t));
	}

	override void finish()
	{
	}

}
