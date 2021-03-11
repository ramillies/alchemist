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
import place;
import reacttext;
import messagebox;
import choicebox;
import player;

import luad.all;
import dsfml.graphics;

struct TeleportInfo
{
	bool ok;
	string text;
}

class TeleportScreen: Screen
{
	private ReactiveText[] texts;
	private World world;
	private Water ocean;
	private View camera, minimap;
	private double zoom, maxZoom;
	private RectangleShape cursor;
	private string heading, msg;
	private LuaTable delegate(size_t, size_t) infoCallback;
	private void delegate(size_t, size_t, bool) resultCallback;
	private Player player;
	private Vertex[] colorcode;
	private TeleportInfo[][] info;

	private RenderWindow win;

	this(World w, Player p, string heading, string msg, LuaTable delegate(size_t, size_t) infoCallback, void delegate(size_t, size_t, bool) resultCallback)
	{
		world = w;
		player = p;
		ocean = new Water(to!int(ceil(world.width/2.)), to!int(world.height));
		this.heading = heading;
		this.msg = msg;
		this.infoCallback = infoCallback;
		this.resultCallback = resultCallback;
		writefln("done constructing");
	}

	override void setWindow(RenderWindow w) { win = w; }

	override void init()
	{
		writefln("begin init");
		camera = win.getDefaultView.dup;
		maxZoom = min(1.*world.pixelSize.x/camera.size.x, 1.*world.pixelSize.y/camera.size.y) - .01;
		zoom = min(1, maxZoom);
		camera.zoom(zoom);
		world.updateTiles;

		writefln("making cursor");
		cursor = new RectangleShape(Vector2f(3*World.TILESIZE*1f, 3*World.TILESIZE*1f));
		cursor.outlineThickness = 8*zoom;
		cursor.fillColor = Color(225, 188, 0, 80);
		cursor.outlineColor = Color(140, 117, 0);

		writefln("making views");
		minimap = new View(FloatRect(0, 0, world.pixelSize.x, world.pixelSize.y));
		camera.center = Vector2f(3*World.TILESIZE*player.x + 3*World.TILESIZE/2, 3*World.TILESIZE*player.y + 3*World.TILESIZE/2);

		writefln("making texts");
		texts = 7.iota.map!((x) => new ReactiveText).array;
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

		texts[1].positionCallback = () => Vector2f(.925*win.size.x, .25*win.size.y);
		texts[1].stringCallback = () => mouseOver() == MouseOver.Map ? world.terrainToString(mouseSquare()) : "";

		texts[2].setFont(Fonts.heading);
		texts[2].setCharacterSize(35);
		texts[2].setRelativeOrigin(Vector2f(.5f, 1f));
		texts[2].setStyle(Text.Style.Bold);
		texts[2].positionCallback = () => Vector2f(.925*win.size.x, .35*win.size.y);
		texts[2].stringCallback = () => mouseOver() == MouseOver.Map ? world.placeName(mouseSquare()) : "";

		texts[3].positionCallback = () => Vector2f(.925*win.size.x, .37*win.size.y);
		texts[3].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[3].setCharacterSize(25);
		texts[3].stringCallback = () => mouseOver() == MouseOver.Map ? world.placeDescription(mouseSquare()) : "";

		with(texts[4])
		{
			setColor(Color(225, 188, 0));
			setRelativeOrigin(Vector2f(.5f, 1f));
			positionCallback = () => Vector2f(.925*win.size.x, .05*win.size.y - 5);
			stringCallback = () => format("%s", player.coins);
		}
		with(texts[5])
		{
			setFont(Fonts.heading);
			setCharacterSize(80);
			setColor(Color.Red);
			setRelativeOrigin(Vector2f(.5f, 0f));
			boxWidth = 0;
			positionCallback = () => Vector2f(.425*win.size.x, .75*win.size.y + 5);
			setString(this.heading);
		}
		with(texts[6])
		{
			setCharacterSize(35);
			setRelativeOrigin(Vector2f(.5f, 0f));
			boxWidth = .85*win.size.x - 20;
			positionCallback = () => Vector2f(.425*win.size.x, .83*win.size.y);
			stringCallback = () => mouseOver() == MouseOver.Map ? info[mouseSquare().y][mouseSquare().x].text : "";
		}

		writefln("getting callback info");
		info = world.height.iota.map!((y) => world.width.iota.map!((x) => TeleportInfo(false, "")).array).array;
		foreach(y; 0 .. world.height)
			foreach(x; 0 .. world.width)
			{
				info[y][x] = getInfo(x, y);
				auto color = info[y][x].ok ? Color(0, 255, 0, 80) : Color(255, 0, 0, 80);
				colorcode ~= Vertex(Vector2f(3*World.TILESIZE*x, 3*World.TILESIZE*y), color, Vector2f(0f, 0f));
				colorcode ~= Vertex(Vector2f(3*World.TILESIZE*(x+1), 3*World.TILESIZE*y), color, Vector2f(0f, 0f));
				colorcode ~= Vertex(Vector2f(3*World.TILESIZE*(x+1), 3*World.TILESIZE*(y+1)), color, Vector2f(0f, 0f));
				colorcode ~= Vertex(Vector2f(3*World.TILESIZE*x, 3*World.TILESIZE*(y+1)), color, Vector2f(0f, 0f));
			}

	}

	private TeleportInfo getInfo(size_t x, size_t y)
	{
		LuaTable t = infoCallback(x, y);
		bool ok = false;
		string text = "";
		if(!t["allowed"].isNil) ok = t.get!bool("allowed");
		if(!t["text"].isNil) text = t.get!string("text");
		return TeleportInfo(ok, text);
	}

	override void event(Event e)
	{
		if(e.type == e.EventType.Closed)
			Mainloop.quit;
		if(e.type == Event.EventType.MouseWheelMoved)
		{
			camera.zoom(clamp(pow(2, -e.mouseWheel.delta/12.), .5/zoom, maxZoom/zoom));
			zoom = clamp(zoom * pow(2, -e.mouseWheel.delta/12.), .5, maxZoom);
		}
		if(e.type == Event.EventType.KeyPressed)
		{
			if(e.key.code == Keyboard.Key.G)
				Settings.drawGrid = !Settings.drawGrid;
			if(e.key.code == Keyboard.Key.Escape)
			{
				Mainloop.popScreen;
				resultCallback(0, 0, false);
			}
		}
		if(e.type == Event.EventType.MouseButtonPressed)
		{
			if(mouseOver() == MouseOver.Map)
			{
				auto pos = mouseSquare();
				if(info[pos.y][pos.x].ok)
				{

					while(Mainloop.screens.length > 1)
						Mainloop.popScreen;
					resultCallback(pos.x, pos.y, true);
				}
			}
		}
	}

	override void update(double dt)
	{
		auto mouse = Mouse.getPosition(win);
		if(mouse.x < win.size.x/20)
			camera.move(Vector2f(-1024*dt, 0));
		if(mouse.y < win.size.y/20)
			camera.move(Vector2f(0, -1024*dt));
		if(mouse.x > win.size.x*19/20)
			camera.move(Vector2f(1024*dt, 0));
		if(mouse.y > win.size.y*19/20)
			camera.move(Vector2f(0, 1024*dt));
		ocean.update(dt);

		texts.each!((t) => t.update);
		cursor.outlineThickness = 8*zoom;
		cursor.position = Vector2f(3*World.TILESIZE * mouseSquare().x, 3*World.TILESIZE * mouseSquare().y);
	}

	override void updateInactive(double dt)
	{
		ocean.update(dt);
		texts[0].update;
		texts[4].update;
	}

	override void draw()
	{
		win.clear();
		camera.viewport = FloatRect(0f, 0f, .85f, .75f);
		camera.size = Vector2f(win.size.x*camera.viewport.width/zoom, win.size.y*camera.viewport.height/zoom);
		normalizeCamera();
		win.view = camera;

		win.draw(ocean);
		win.draw(world);
		win.draw(player);
		if(mouseOver == MouseOver.Map)
			win.draw(cursor);
		win.draw(colorcode, PrimitiveType.Quads);

		win.view = minimap;
		minimap.viewport = FloatRect(.875f, .05f, .10f, .10f*win.size.x/win.size.y);
		win.draw(ocean);
		bool grid = Settings.drawGrid;
		Settings.drawGrid = false;
		win.draw(world);
		Settings.drawGrid = grid;

		RectangleShape rect = new RectangleShape(camera.size);
		rect.fillColor = Color(0,0,0,0);
		rect.outlineThickness = 2*world.pixelSize.x/.1/win.size.x;
		rect.outlineColor = Color.Red;
		rect.position = Vector2f(camera.center.x - camera.size.x/2, camera.center.y - camera.size.y/2);
		win.draw(rect);

		win.view = win.getDefaultView;

		texts.each!((t) => win.draw(t));
	}

	override void finish()
	{
	}

	private void normalizeCamera()
	{
		camera.center = Vector2f(
			clamp(camera.center.x, camera.size.x/2, world.pixelSize.x - camera.size.x/2),
			clamp(camera.center.y, camera.size.y/2, world.pixelSize.y - camera.size.y/2)
		);
	}

	private enum MouseOver { Map, GameLog, InfoPanel }
	private MouseOver mouseOver()
	{
		auto mouse = Mouse.getPosition(win);
		if(Settings.gameLogShown)
		{
			if(FloatRect(0f, 0f, .85 * win.size.x, .75 * win.size.y).contains(mouse))
				return MouseOver.Map;
			else if(FloatRect(0, .75*win.size.y, .85*win.size.x, win.size.y).contains(mouse))
				return MouseOver.GameLog;
			else
				return MouseOver.InfoPanel;

		}
		else
		{
			if(FloatRect(0f, 0f, .85 * win.size.x, win.size.y).contains(mouse))
				return MouseOver.Map;
			else
				return MouseOver.InfoPanel;
		}
	}

	private Vector2u mouseSquare()
	{
		if(mouseOver() == MouseOver.Map)
		{
			auto pt = win.mapPixelToCoords(Mouse.getPosition(win), camera);
			return Vector2u(
				to!uint(clamp(pt.x/3/World.TILESIZE, 0, world.width-1)),
				to!uint(clamp(pt.y/3/World.TILESIZE, 0, world.height-1))
			);
		}
		else
			return Vector2u(0, 0);
	}
}
