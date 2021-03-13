import std.algorithm, std.array, std.range;
import std.conv;

import reacttext;
import animation;

import dsfml.graphics;

class FlyingText: ReactiveText, Animation
{
	private Vector2f speed;
	private Color startingColor;
	private double alpha;
	double vanishSpeed;

	this() { super(); }

	override @property bool animationFinished() { return alpha <= 0; }
	void initAnimation(Vector2f spd, double vanishSpd)
	{
		this.update();
		startingColor = this.getColor();
		alpha = to!double(startingColor.a);
		speed = spd;
		vanishSpeed = vanishSpd;
	}

	void updateAnimation(double dt)
	{
		this.position = this.position + Vector2f(speed.x*dt, speed.y*dt);
		alpha -= dt * vanishSpeed;
		this.setColor(Color(startingColor.r, startingColor.g, startingColor.b, to!ubyte(clamp(alpha, 0., 255.))));
	}
}
