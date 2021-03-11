import std.algorithm;

import player;
import potiontable;
import reacttext;
import mainloop;
import resources;

import dsfml.graphics;

class VictoryScreen: Screen
{
	private ReactiveText[] texts;
	private Player player;
	private PotionTable table;
	private RenderWindow win;

	this(Player p, PotionTable t)
	{
		player = p;
		table = t;
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		texts ~= new ReactiveText;
		with(texts[$-1])
		{
			setString("Victory!");
			setColor(Color.Red);
			position = Vector2f(win.size.x/2, win.size.y/2);
			setRelativeOrigin(Vector2f(.5f, .5f));
			setCharacterSize(win.size.y / 9);
			setFont(Fonts.heading);
		}
	}

	override void event(Event e)
	{
		if(e.type == Event.EventType.KeyPressed)
			Mainloop.quit;
	}

	override void update(double dt) { texts.each!`a.update`; }
	override void updateInactive(double dt) { }

	override void draw()
	{
		win.clear();
		foreach(text; texts)
			win.draw(text);
	}

	override void finish() { }
}
