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

class GameScreen: Screen
{
	private ReactiveText[] texts;
	private World world;
	private Water ocean;
	private View camera, minimap;
	private double zoom, maxZoom;
	private Player player;
	private RectangleShape cursor;
	private GameTime time;

	private RenderWindow win;

	this(World w, GameTime t)
	{
		world = w;
		time = t;

		ocean = new Water(to!int(ceil(world.width/2.)), to!int(world.height));
		auto startPos = cartesianProduct(world.width.iota, world.height.iota).filter!((x) => world.features[x[1]][x[0]] == "city").array.choice;
		player = new Player(startPos[0], startPos[1]);
	}

	override void setWindow(RenderWindow w)
	{
		win = w;
	}

	override void init()
	{
		camera = win.getDefaultView.dup;
		maxZoom = min(1.*world.pixelSize.x/camera.size.x, 1.*world.pixelSize.y/camera.size.y) - .01;
		zoom = min(1, maxZoom);
		camera.zoom(zoom);
		world.updateTiles;

		cursor = new RectangleShape(Vector2f(3*World.TILESIZE*1f, 3*World.TILESIZE*1f));
		cursor.outlineThickness = 8*zoom;
		cursor.fillColor = Color(225, 188, 0, 80);
		cursor.outlineColor = Color(140, 117, 0);

		minimap = new View(FloatRect(0, 0, world.pixelSize.x, world.pixelSize.y));
		camera.center = Vector2f(3*World.TILESIZE*player.x + 3*World.TILESIZE/2, 3*World.TILESIZE*player.y + 3*World.TILESIZE/2);

		texts = 5.iota.map!((x) => new ReactiveText).array;
		foreach(text; texts)
		{
			text.setFont(Fonts.text);
			text.setCharacterSize(30);
			text.setColor(Color.White);
			text.setRelativeOrigin(Vector2f(.5f, .5f));
			text.boxWidth = .15*win.size.x - 10;
		}

		texts[0].setCharacterSize(20);
		texts[0].positionCallback = () => Vector2f(.925*win.size.x, .025*win.size.y);
		texts[0].stringCallback = delegate string()
		{
			auto systime = std.datetime.systime.Clock.currTime;
			return format("%02u:%02u", systime.hour, systime.minute);
		};

		texts[1].positionCallback = () => Vector2f(.925*win.size.x, .95*win.size.y);
		texts[1].stringCallback = () => time.uiString;

		texts[2].positionCallback = () => Vector2f(.925*win.size.x, .25*win.size.y);
		texts[2].stringCallback = () => mouseOver() == MouseOver.Map ? world.terrainToString(mouseSquare()) : "";

		texts[3].setFont(Fonts.heading);
		texts[3].setCharacterSize(35);
		texts[3].setRelativeOrigin(Vector2f(.5f, 1f));
		texts[3].setStyle(Text.Style.Bold);
		texts[3].positionCallback = () => Vector2f(.925*win.size.x, .35*win.size.y);
		texts[3].stringCallback = () => mouseOver() == MouseOver.Map ? world.placeName(mouseSquare()) : "";

		texts[4].positionCallback = () => Vector2f(.925*win.size.x, .37*win.size.y);
		texts[4].setRelativeOrigin(Vector2f(.5f, 0f));
		texts[4].setCharacterSize(25);
		texts[4].stringCallback = () => mouseOver() == MouseOver.Map ? world.placeDescription(mouseSquare()) : "";

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
			if(e.key.code == Keyboard.Key.BackSpace)
				Settings.gameLogShown = !Settings.gameLogShown;
			if(e.key.code == Keyboard.Key.W || e.key.code == Keyboard.Key.Up)
				attemptMove(0, -1);
			if(e.key.code == Keyboard.Key.A || e.key.code == Keyboard.Key.Left)
				attemptMove(-1, 0);
			if(e.key.code == Keyboard.Key.S || e.key.code == Keyboard.Key.Down)
				attemptMove(0, 1);
			if(e.key.code == Keyboard.Key.D || e.key.code == Keyboard.Key.Right)
				attemptMove(1, 0);
			if(e.key.code == Keyboard.Key.Return)
				world.enterPlace(player);
			if(e.key.code == Keyboard.Key.R)
				Mainloop.pushScreen(new ChoiceBox("Wait",
					"You can let pass some time if you want — the world around you will still go on. There is no other advantage.",
					[
						Choice(null, "Do not wait", delegate void() { }, new ReactiveText),
						Choice(null, "Wait one week", delegate void() { time.advance(7); }, new ReactiveText),
						Choice(null, "Wait one month ", delegate void() { time.advance(28); }, new ReactiveText),
						Choice(null, "Wait three months", delegate void() { time.advance(84); }, new ReactiveText),
						Choice(null, "Wait one year", delegate void() { time.advance(336); }, new ReactiveText),
					]
				));
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

	override void updateInactive(double dt) { ocean.update(dt); }

	override void draw()
	{
		if(Settings.gameLogShown)
			camera.viewport = FloatRect(0f, 0f, .85f, .75f);
		else
			camera.viewport = FloatRect(0f, 0f, .85f, 1f);
		camera.size = Vector2f(win.size.x*camera.viewport.width/zoom, win.size.y*camera.viewport.height/zoom);
		normalizeCamera();
		win.view = camera;

		win.draw(ocean);
		win.draw(world);
		win.draw(player);
		if(mouseOver == MouseOver.Map)
			win.draw(cursor);

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

	private void attemptMove(int dx, int dy)
	{
		if(world.passable(player.x + dx, player.y + dy))
		{
			player.x += dx;
			player.y += dy;
			world.passTimeForMove(player.x, player.y);
		}
		camera.center = Vector2f(3*World.TILESIZE*player.x + 3*World.TILESIZE/2, 3*World.TILESIZE*player.y + 3*World.TILESIZE/2);
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
