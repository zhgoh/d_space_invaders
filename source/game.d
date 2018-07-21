import derelict.glfw3.glfw3;
import derelict.opengl;

import std.experimental.logger;
import std.stdio;
import std.typecons;
import std.string : format, fromStringz;

import shaders;
import buffer;
import sprite;

version(Windows) string libName = "dlls\\glfw3.dll";
else string libName = "glfw3.so";

// Player state
static auto playerDir = 0;

// Whether fired
static auto firePressed = false;

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

struct GameState
{
  size_t width, height;
  size_t num_aliens;
  size_t num_bullets;
  Alien[] aliens;
  Player player;
  Bullet[128] bullets;
}

GameState createGame(size_t buffer_width, size_t buffer_height)
{
  GameState game;
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

class Game
{
  private static bool isRunning;
  private uint width, height;
  private GLFWwindow *window;

  this(uint width, uint height)
  {
    this.width = width;
    this.height = height;

    isRunning = true;
  }

  bool InitGL()
  {
    // Using Derelict to load openGL/GLFW
    DerelictGL3.load();
    DerelictGLFW3.load("dlls\\glfw3.dll");

    // Setting error callbacks
    glfwSetErrorCallback(&error_callback);

    if (!glfwInit())
    {
      fatal("glfw failed to init");
      return false;
    }

    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    
    window = glfwCreateWindow(2 * width, 2 * height, "Space Invaders", null, null);
    if(window is null)
    {
      fatal("glfw failed to create window");
      glfwTerminate();
      return false;
    }

    // Setting key callbacks
    glfwSetKeyCallback(window, &key_callback);

    glfwShowWindow(window);
    glfwMakeContextCurrent(window);

    // Turning on vsync
    glfwSwapInterval(1);

    // Reload after making context to use GL 3 core features
    DerelictGL3.reload();

    return true;
  }

  public void Run()
  {
    if (!InitGL())
    return;
    
    auto clearColor = rgbToUint(0, 128, 0);

    Buffer buffer;
    buffer.width = width;
    buffer.height = height;
    buffer.data = new uint[buffer.width * buffer.height];
    bufferClear(&buffer, clearColor);

    GLuint buffer_texture;
    glGenTextures(1, &buffer_texture);
    glBindTexture(GL_TEXTURE_2D, buffer_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, buffer.width, buffer.height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, cast(char *)buffer.data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    GLuint fullscreen_triangle_vao;
    glGenVertexArrays(1, &fullscreen_triangle_vao);

    auto shaderID = createShaders();
    if(!validateProgram(shaderID))
    {
      fatal("Error while validating shader.");
      glfwTerminate();
      glDeleteVertexArrays(1, &fullscreen_triangle_vao);

      return;
    }

    glUseProgram(shaderID);
    GLint location = glGetUniformLocation(shaderID, "buffer");
    glUniform1i(location, 0);

    glDisable(GL_DEPTH_TEST);
    glActiveTexture(GL_TEXTURE0);
    glBindVertexArray(fullscreen_triangle_vao);

    auto alienAnim = createAlienAnimation();
    const auto playerSprite = createPlayerSprite();
    const auto bulletSprite = createBulletSprite();
    const auto textSprite = createTextSprite();
    const auto numberSprite = createNumberSprite();
    auto gameState = createGame(width, height);

    // Set Alien position
    for (size_t yi = 0; yi < 5; ++yi)
    {
      for (size_t xi = 0; xi < 11; ++xi)
      {
        auto alien = &gameState.aliens[yi * 11 + xi];
        alien.type = cast(ubyte) (5 - yi) / 2 + 1;

        alien.x = 16 * xi + 20;
        alien.y = 17 * yi + 128;
      }
    }

    auto death_counters = new ubyte[gameState.num_aliens];
    for (size_t i = 0; i < gameState.num_aliens; ++i)
    {
      death_counters[i] = 10;
    }

    size_t score = 0;

    // Main loop
    while (!glfwWindowShouldClose(window) && isRunning)
    {
      loopAnim(alienAnim);

      const auto newDir = playerDir * 2;

      if (newDir != 0)
      {
        if (gameState.player.x + playerSprite.width + newDir >= gameState.width)
        {
          gameState.player.x = gameState.width - playerSprite.width;
        }
        else if (cast (int)gameState.player.x + newDir <= 0)
        {
          gameState.player.x = 0;
        }
        else 
          gameState.player.x += newDir;
      }

      //glClear(GL_COLOR_BUFFER_BIT);
      bufferClear(&buffer, clearColor);

      // Drawing of UI/Text
      bufferDrawText(&buffer, textSprite, "SCORE", 4, gameState.height - textSprite.height - 7, rgbToUint(128, 0, 0));
      bufferDrawNumber(&buffer, numberSprite, score, 4 + 2 * numberSprite.width, gameState.height - 2 * numberSprite.height - 12, rgbToUint(128, 0, 0));
      bufferDrawText(&buffer, textSprite, "CREDIT 00", 164, 7, rgbToUint(128, 0, 0));
      for (size_t i = 0; i < gameState.width; ++i)
      {
        buffer.data[gameState.width * 16 + i] = rgbToUint(128, 0, 0);
      }

      for (size_t ai = 0; ai < gameState.num_aliens; ++ai)
      {
        if(!death_counters[ai]) 
          continue;
        
        const auto alien = &gameState.aliens[ai];

        if (alien.type == AlienType.ALIEN_DEAD)
        {
          // Draw death sprite
          bufferDraw(&buffer, alienAnim.frames[6], alien.x, alien.y, rgbToUint(128, 0, 0));
        }
        else
        {
          size_t current_frame = alienAnim.time / alienAnim.frame_duration;
          const auto sprite = alienAnim.frames[current_frame];
          bufferDraw(&buffer, sprite, alien.x, alien.y, rgbToUint(128, 0, 0));
        }
      }

      for (size_t bi = 0; bi < gameState.num_bullets; ++bi)
      {
        const auto bullet = &gameState.bullets[bi];
        bufferDraw(&buffer, bulletSprite, bullet.x, bullet.y, rgbToUint(128, 0, 0));
      }

      // Simulate bullets
      for (size_t bi = 0; bi < gameState.num_bullets;)
      {
        gameState.bullets[bi].y += gameState.bullets[bi].dir;
        if (gameState.bullets[bi].y >= gameState.height ||
          gameState.bullets[bi].y < bulletSprite.height)
        {
            gameState.bullets[bi] = gameState.bullets[gameState.num_bullets - 1];
            --gameState.num_bullets;
            continue;
        }

        // Check hit
        for (size_t ai = 0; ai < gameState.num_aliens; ++ai)
        {
          const auto alien = &gameState.aliens[ai];
          if (alien.type == AlienType.ALIEN_DEAD) 
            continue;

          const auto animation = &alienAnim;
          size_t current_frame = animation.time / animation.frame_duration;
          const auto alien_sprite = &animation.frames[current_frame];
          bool overlap = overlapCheck(
            bulletSprite, gameState.bullets[bi].x, gameState.bullets[bi].y,
            *alien_sprite, alien.x, alien.y
          );
          
          if (overlap)
          {
            gameState.aliens[ai].type = AlienType.ALIEN_DEAD;

            score += 10 * (4 - gameState.aliens[ai].type);

            // NOTE: Hack to recenter death sprite
            gameState.aliens[ai].x -= (alienAnim.frames[6].width - alien_sprite.width)/2;
            gameState.bullets[bi] = gameState.bullets[gameState.num_bullets - 1];
            --gameState.num_bullets;
            continue;
          }
        }
        
        ++bi;
      }

      bufferDraw(&buffer, playerSprite, gameState.player.x, gameState.player.y, rgbToUint(128, 0, 0));

      glTexSubImage2D(
        GL_TEXTURE_2D, 0, 0, 0,
        buffer.width, buffer.height,
        GL_RGBA, GL_UNSIGNED_INT_8_8_8_8,
        cast(char *)buffer.data
      );
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

      glfwSwapBuffers(window);
      glfwPollEvents();

      // Simulate aliens
      for (size_t ai = 0; ai < gameState.num_aliens; ++ai)
      {
        const auto alien = &gameState.aliens[ai];
        if (alien.type == AlienType.ALIEN_DEAD && death_counters[ai])
        {
          --death_counters[ai];
        }
      }

      // SImulate bullets
      if (firePressed && gameState.num_bullets < 128)
      {
        gameState.bullets[gameState.num_bullets].x = gameState.player.x + playerSprite.width / 2;
        gameState.bullets[gameState.num_bullets].y = gameState.player.y + playerSprite.height;
        gameState.bullets[gameState.num_bullets].dir = 2;
        ++gameState.num_bullets;
      }
      firePressed = false;
    }

    glDeleteVertexArrays(1, &fullscreen_triangle_vao);
    
    glfwDestroyWindow(window);
    glfwTerminate();
  }

  public static void Stop() nothrow
  {
    isRunning = false;
  }
}

extern(C) nothrow
{
	void error_callback(int error, const(char)* description)
	{
		throw new Error(format("Error: %s : %s", error, fromStringz(description)));
  }

  void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
  {
    switch(key)
    {
    case GLFW_KEY_ESCAPE:
      if(action == GLFW_PRESS) 
        Game.Stop();
      break;

    case GLFW_KEY_D:
    case GLFW_KEY_RIGHT:
      if(action == GLFW_PRESS) 
        playerDir += 1;
      else if(action == GLFW_RELEASE) 
        playerDir -= 1;
      break;

    case GLFW_KEY_A:
    case GLFW_KEY_LEFT:
      if(action == GLFW_PRESS) 
        playerDir -= 1;
      else if(action == GLFW_RELEASE) 
        playerDir += 1;
      break;
    
    case GLFW_KEY_SPACE:
      if (action == GLFW_RELEASE) 
        firePressed = true;
      break;

    default:
      break;
    }
  } 
}