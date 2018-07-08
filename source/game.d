struct Alien
{
  size_t x, y;
  ubyte type;
}

struct Player
{
  size_t x, y;
  size_t life;
}

struct Game
{
  size_t width, height;
  size_t num_aliens;
  size_t num_bullets;
  Alien[] aliens;
  Player player;
  Bullet[128] bullets;
}

Game createGame(size_t buffer_width, size_t buffer_height)
{
  Game game;
  game.width = buffer_width;
  game.height = buffer_height;
  game.num_aliens = 55;
  game.aliens = new Alien[game.num_aliens];

  game.player.x = 112 - 5;
  game.player.y = 32;

  game.player.life = 3;
  
  return game;
}

struct Bullet
{
    size_t x, y;
    int dir;
};