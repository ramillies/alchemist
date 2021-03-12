import std.array;
import std.algorithm;
import std.stdio;
import std.json;
import std.range;
import std.conv;

import mainloop;
import resources;
import reacttext;
import coolsprite;

import luad.all;
import dsfml.graphics;

struct Choice
{
	CoolSprite sprite;
	string text;
	void delegate() callback;
	ReactiveText textRendering;
	bool disabled = false, popBox = true;

	static Choice fromLuaTable(LuaTable obj)
	{
		CoolSprite sprite;
		string text = "";
		void delegate() callback = delegate void() { };
		ReactiveText t = new ReactiveText;
		bool disabled = false;
		bool popBox = true;
		
		if(!obj["text"].isNil) text = obj.get!string("text");
		if(!obj["callback"].isNil) callback = obj.get!(void delegate())("callback");
		if(!obj["disabled"].isNil) disabled = obj.get!bool("disabled");
		if(!obj["popBox"].isNil) popBox = obj.get!bool("popBox");
		if(!obj["tileset"].isNil && Images.exists(obj.get!string("tileset")))
		{
			sprite = new CoolSprite;
			sprite.setTextureByName(obj.get!string("tileset"));
			if(!obj["tilenumber"].isNil)
				sprite.tilenumber = obj.get!int("tilenumber");
		}

		return Choice(sprite, text, callback, t, disabled, popBox);
	}
}

class ChoiceBox: Screen
{
	private ReactiveText[] texts;
	private RenderWindow win;
	private string heading, msg;
	private Choice[] choices;
	const int ROWHEIGHT = 65;
	private View camera;
	private RectangleShape cursor;

	private double choicesTop, choicesHeight;

	this(string h, string m, Choice[] c)
	{
		heading = h;
		msg = m;
		choices = c;
	}

	override void init()
	{
		texts = 3.iota.map!((x) => new ReactiveText).array;
		foreach(txt; texts)
		{
			txt.setFont(Fonts.text);
			txt.setColor(Color.White);
			txt.boxWidth = win.size.x/2 - 50;
		}
		with(texts[0])
		{
			setFont(Fonts.heading);
			setCharacterSize(80);
			setColor(Color.Red);
			setStyle(Text.Style.Bold);
			setRelativeOrigin(Vector2f(.5f, 0f));
			positionCallback = () => Vector2f(.5*win.size.x, .05*win.size.y + 5);
			setString(heading);
		}
		with(texts[1])
		{
			setCharacterSize(40);
			setRelativeOrigin(Vector2f(.5f, 0f));
			positionCallback = () => Vector2f(.5*win.size.x, .12*win.size.y);
			setString(msg);
		}
		with(texts[2])
		{
			setFont(Fonts.italic);
			setCharacterSize(25);
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.5*win.size.x, .95*win.size.y - 10);
			stringCallback = () => "(Scroll and click with mouse.)";
		}

		foreach(n, choice; choices)
		{
			with(choice.textRendering)
			{
				setFont(Fonts.text);
				sizeCallback = () => 35;
				boxWidth = win.size.x/2 - ROWHEIGHT;
				if(choice.disabled)
					setColor(Color(100, 100, 100));
				else
					setColor(Color.White);
				setRelativeOrigin(Vector2f(0f, .5f));
				position = Vector2f(ROWHEIGHT+20, n*ROWHEIGHT + ROWHEIGHT/2);
				setString(choice.text);
			}
			if(choice.sprite !is null)
			{
				with(choice.sprite)
				{
					setRelativeOrigin(Vector2f(.5f, .5f));
					position = Vector2f(ROWHEIGHT/2, ROWHEIGHT/2 + n*ROWHEIGHT);
					auto bound = getLocalBounds();
					scale = Vector2f(ROWHEIGHT/bound.height, ROWHEIGHT/bound.height);
					if(choice.disabled)
						color = Color(100, 100, 100);
				}
			}
		}

		texts[1].update;
		auto bounds = texts[1].getGlobalBounds;
		choicesTop = (bounds.top + bounds.height + 60)/win.size.y;
		choicesHeight = .92 - choicesTop;

		if(choicesHeight < 0.1)
		{
			choicesTop = .82;
			choicesHeight = .10;
		}

		camera = new View(FloatRect(0, 0, .45 * win.size.x, choicesHeight * win.size.y));
		camera.viewport = FloatRect(.275f, choicesTop, .45f, choicesHeight);

		cursor = new RectangleShape(Vector2f(.45*win.size.x, ROWHEIGHT));
		cursor.fillColor = Color(225, 188, 0, 80);
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void event(Event e)
	{
		if(e.type == Event.EventType.MouseWheelMoved)
			camera.center = Vector2f(camera.center.x, clamp(camera.center.y - ROWHEIGHT*e.mouseWheel.delta, camera.size.y/2, max(choices.length*ROWHEIGHT - camera.size.y/2, camera.size.y/2)));
		if(e.type == Event.EventType.MouseButtonPressed)
		{
			if(e.mouseButton.button == Mouse.Button.Left && mouseInBox() && !choices[mouseRow()].disabled)
			{
				if(choices[mouseRow()].popBox)
					Mainloop.popScreen;
				choices[mouseRow()].callback();
			}
		}
	}

	override void update(double dt)
	{
		texts.each!((t) => t.update);
		choices.each!((c) => c.textRendering.update);
	}

	override void updateInactive(double dt) { }

	override void draw()
	{
		RectangleShape r = new RectangleShape(Vector2f(.5 * win.size.x, .9*win.size.y));
		r.fillColor = Color.Black;
		r.outlineThickness = win.size.x/100;
		r.outlineColor = Color.Red;
		r.position = Vector2f(.25*win.size.x, .04*win.size.y);

		win.draw(r);
		texts.each!((t) => win.draw(t));

		if(camera.size.y < choices.length*ROWHEIGHT)
		{
			RectangleShape bar = new RectangleShape(Vector2f(10f, camera.size.y ^^ 2 /ROWHEIGHT/choices.length));
			bar.fillColor = Color.Red;
			bar.position = Vector2f(.7375*win.size.x - 5, choicesTop*win.size.y + camera.size.y * (camera.center.y - camera.size.y/2)/choices.length/ROWHEIGHT);
			win.draw(bar);
		}

		win.view = camera;
		foreach(c; choices)
		{
			if(c.sprite !is null)
				win.draw(c.sprite);
			win.draw(c.textRendering);
		}
		if(mouseInBox() && !choices[mouseRow()].disabled)
		{
			cursor.position = Vector2f(0f, ROWHEIGHT*mouseRow());
			win.draw(cursor);
		}

		win.view = win.getDefaultView.dup;
	}

	private bool mouseInBox()
	{
		auto cw = camera.viewport;
		return FloatRect(cw.left*win.size.x, cw.top*win.size.y, cw.width*win.size.x, cw.height*win.size.y).contains(Mouse.getPosition(win));
	}

	private int mouseRow()
	{
		auto cw = camera.viewport;
		if(mouseInBox())
		{
			auto pt = win.mapPixelToCoords(Mouse.getPosition(win), camera);
			return clamp(to!int(pt.y/ROWHEIGHT), 0, choices.length-1);
		}
		else
			return 0;
	}

	override void finish()
	{
	}
}

