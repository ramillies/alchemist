import boilerplate;
import dsfml.graphics;

class ReactiveText: Text
{
	private
	{
		@Write string delegate() _stringCallback;
		@Write Color delegate() _colorCallback;
		@Write Text.Style delegate() _styleCallback;
		@Write uint delegate() _sizeCallback;
		@Write Vector2f delegate() _positionCallback;
		@Read bool _relativeOriginAllowed;
		@Read Vector2f _relativeOrigin;
	}

	mixin(GenerateFieldAccessors);

	this()
	{
		super();
		_stringCallback = delegate string() { return this.getString(); };
		_colorCallback = delegate Color() { return this.getColor(); };
		_styleCallback = delegate Text.Style () { return this.getStyle(); };
		_sizeCallback = delegate uint () { return this.getCharacterSize(); };
		_positionCallback = delegate Vector2f () { return this.position; };
		_relativeOrigin = Vector2f(0f, 0f);
		_relativeOriginAllowed = false;
	}

	private void updatePosition()
	{
		if(_relativeOriginAllowed)
		{
			auto bounds = this.getLocalBounds();
			this.origin = Vector2f(bounds.width*_relativeOrigin.x, bounds.height*_relativeOrigin.y);
		}
	}

	void setRelativeOrigin(Vector2f u)
	{
		_relativeOriginAllowed = true;
		_relativeOrigin = u;
	}

	void disableRelativeOrigin() { _relativeOriginAllowed = false; }

	void update()
	{
		this.setString(_stringCallback());
		this.setColor(_colorCallback());
		this.setStyle(_styleCallback());
		this.setCharacterSize(_sizeCallback());
		this.position = _positionCallback();

		updatePosition();
	}

}
