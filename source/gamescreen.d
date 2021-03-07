import std.range;
import std.random;
import std.algorithm;
import std.array;
import std.stdio;
import std.format;
import std.math;
import std.conv;

import mainloop;
import resources;
import tilemap;
import world;
import water;
import settings;

import dsfml.graphics;

class GameScreen: Screen
{
	private Text text;
	private World world;
	private Water ocean;
	private View camera, minimap;
	private double zoom, maxZoom;

	private RenderWindow win;

	this(World w)
	{
		text = new Text;
		text.setFont(Fonts.gentium);
		text.setCharacterSize(30);
		text.setColor = Color.Red;
		auto bounds = text.getGlobalBounds;
		text.position = Vector2f(0, 0);

		world = w;
		writefln("World: %s", world);
		ocean = new Water(to!int(ceil(world.width/2.)), to!int(world.height));

		writefln("Constructed game screen");
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
		world.prepareDrawing;

		minimap = new View(FloatRect(0, 0, world.pixelSize.x, world.pixelSize.y));
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

		win.view = minimap;
		minimap.viewport = FloatRect(.875f, 0f, .10f, .10f*win.size.x/win.size.y);
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
}
