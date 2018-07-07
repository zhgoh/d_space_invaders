struct Buffer
{
  size_t width, height;
  uint[] data;
}

ubyte rgbToUint32(ubyte r, ubyte g, ubyte b)
{
  return cast(ubyte) ((r << 24) | (g << 16) | (b << 8) | 255);
}

void bufferClear(Buffer *buffer, uint color)
{
  const auto dimension = buffer.width * buffer.height;
  for (size_t i = 0; i < dimension; ++i)
  {
    buffer.data[i] = color;
  }
}