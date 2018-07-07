import sprite;

struct Buffer
{
  size_t width, height;
  uint[] data;
}

uint rgbToUint(ubyte r, ubyte g, ubyte b)
{
  return (r << 24) | (g << 16) | (b << 8) | 255;
}

void bufferClear(Buffer *buffer, uint color)
{
  const auto dimension = buffer.width * buffer.height;
  for (size_t i = 0; i < dimension; ++i)
  {
    buffer.data[i] = color;
  }
}

void bufferDraw(
    Buffer* buffer, const ref Sprite sprite,
    size_t x, size_t y, uint color
)
{
  for (size_t xi = 0; xi < sprite.width; ++xi)
  {
    for (size_t yi = 0; yi < sprite.height; ++yi)
    {
      size_t sy = sprite.height - 1 + y - yi;
      size_t sx = x + xi;

      if(sprite.data[yi * sprite.width + xi] && 
         sy < buffer.height && sx < buffer.width) 
      {
        buffer.data[sy * buffer.width + sx] = color;
      }
    }
  }
}