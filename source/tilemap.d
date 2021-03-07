import dsfml.graphics;

class Tilemap : Drawable, Transformable
{
    private
    {
        VertexArray m_vertices;
        Texture m_tileset;
	uint sizeX, sizeY;
    }

    mixin NormalTransformable;

    this()
    {
        m_tileset = new Texture;
    }

    @property Vector2f size() { return Vector2f(sizeX, sizeY); }

    bool load(Texture tileset, Vector2u tileSize, const(int[][]) tiles)
    {
        // load the tileset texture
	m_tileset = tileset;
	uint width = cast(uint) tiles[0].length;
	uint height = cast(uint) tiles.length;

        // resize the vertex array to fit the level size
        m_vertices = new VertexArray(PrimitiveType.Quads, width * height * 4);

        // populate the vertex array, with one quad per tile
        for (uint i = 0; i < width; ++i)
            for (uint j = 0; j < height; ++j)
            {
                // get the current tile number
                int tileNumber = tiles[j][i];

                // find its position in the tileset texture
                int tu = tileNumber % (m_tileset.getSize.x / tileSize.x);
                int tv = tileNumber / (m_tileset.getSize.x / tileSize.x);

                // get a pointer to the current tile's quad
                uint quad = (i + j * width) * 4;

                // define its 4 corners
                m_vertices[quad + 0].position = Vector2f(i * tileSize.x, j * tileSize.y);
                m_vertices[quad + 1].position = Vector2f((i + 1) * tileSize.x, j * tileSize.y);
                m_vertices[quad + 2].position = Vector2f((i + 1) * tileSize.x, (j + 1) * tileSize.y);
                m_vertices[quad + 3].position = Vector2f(i * tileSize.x, (j + 1) * tileSize.y);

                // define its 4 texture coordinates
                m_vertices[quad + 0].texCoords = Vector2f(tu * tileSize.x, tv * tileSize.y);
                m_vertices[quad + 1].texCoords = Vector2f((tu + 1) * tileSize.x, tv * tileSize.y);
                m_vertices[quad + 2].texCoords = Vector2f((tu + 1) * tileSize.x, (tv + 1) * tileSize.y);
                m_vertices[quad + 3].texCoords = Vector2f(tu * tileSize.x, (tv + 1) * tileSize.y);
            }

	sizeX = width*tileSize.x;
	sizeY = height*tileSize.y;
        return true;
    }

    override void draw(RenderTarget target, RenderStates states = RenderStates.Default)
    {
        // apply the transform
        states.transform *= getTransform();

        // apply the tileset texture
        states.texture = m_tileset;

        // draw the vertex array
        target.draw(m_vertices, states);
    }

}
