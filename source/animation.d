import dsfml.graphics;

interface Animation: Drawable
{
	@property bool animationFinished();
	void updateAnimation(double);
}
