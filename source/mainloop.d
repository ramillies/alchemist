import dsfml.graphics;

interface Screen
{
	void init();
	void setWindow(RenderWindow win);
	void event(Event e);
	void update(double dt);
	void draw();
	void finish();
}

class Mainloop
{
	static Screen screen = null;
	static bool shouldQuit = false;
	static Clock clock = null;
	static RenderWindow win = null;

	static void quit()
	{
		shouldQuit = true;
	}

	static void changeScreen(Screen s)
	{
		if(!clock) clock = new Clock;
		if(screen) screen.finish;
		screen = s;
		screen.setWindow(win);
		screen.init;
		clock.restart;
	}

	static void mainloop()
	{
		if(!(screen && win))
			return;

		while(!shouldQuit)
		{
			Event e;
			while(win.pollEvent(e))
				screen.event(e);
			screen.update(clock.getElapsedTime.total!"hnsecs" * 1e-7);
			clock.restart;

			win.clear;
			screen.draw;
			win.display;
		}

		screen.finish;
	}
}
