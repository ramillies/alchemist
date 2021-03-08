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

import dsfml.graphics;

class GameScreen: Screen
{
	private ReactiveText realtime, gametime;
	private World world;
	private Water ocean;
	private View camera, minimap;
	private double zoom, maxZoom;
	private Player player;

	private RenderWindow win;

	this(World w)
	{
		world = w;
		realtime = new ReactiveText;
		gametime = new ReactiveText;

		ocean = new Water(to!int(ceil(world.width/2.)), to!int(world.height));
		auto startPos = cartesianProduct(world.width.iota, world.height.iota).filter!((x) => world.features[x[1]][x[0]] == "city").array.choice;
		writefln("Starting pos %s", startPos);
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

		minimap = new View(FloatRect(0, 0, world.pixelSize.x, world.pixelSize.y));
		camera.center = Vector2f(3*World.TILESIZE*player.x + 3*World.TILESIZE/2, 3*World.TILESIZE*player.y + 3*World.TILESIZE/2);

		realtime.setFont(Fonts.text);
		realtime.setCharacterSize(20);
		realtime.setColor(Color.White);
		realtime.setRelativeOrigin(Vector2f(.5f, .5f));
		realtime.positionCallback = () => Vector2f(.925*win.size.x, .025*win.size.y);
		realtime.stringCallback = delegate string()
		{
			auto systime = std.datetime.systime.Clock.currTime;
			return format("%02u:%02u", systime.hour, systime.minute);
		};

		gametime.setFont(Fonts.text);
		gametime.setCharacterSize(30);
		gametime.setColor(Color.White);
		gametime.setRelativeOrigin(Vector2f(.5f, .5f));
		gametime.positionCallback = () => Vector2f(.925*win.size.x, .95*win.size.y);
		gametime.stringCallback = () => format("Day %s", world.days);
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

		realtime.update;
		gametime.update;
	}

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
		win.draw(realtime);
		win.draw(gametime);
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
}
