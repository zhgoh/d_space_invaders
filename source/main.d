import derelict.glfw3.glfw3;
import derelict.opengl;

import std.experimental.logger;
import std.stdio;
import std.typecons;
import std.string : format, fromStringz;

import shaders;
import buffer;
import sprite;
import game;

version(Windows) string libName = "dlls\\glfw3.dll";
else string libName = "glfw3.so";

static const auto buffer_width = 224;
static const auto buffer_height = 256;

// Game running state
static auto isRunning = true;

// Player state
static auto playerDir = 0;

// Whether fired
static auto firePressed = false;

void main()
{
  // Using Derelict to load openGL/GLFW
  DerelictGL3.load();
  DerelictGLFW3.load("dlls\\glfw3.dll");

  // Setting error callbacks
  glfwSetErrorCallback(&error_callback);

  if (!glfwInit())
  {
    fatal("glfw failed to init");
    return;
  }

  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
  
  auto window = glfwCreateWindow(640, 480, "Space Invaders", null, null);
  if(window is null)
  {
    fatal("glfw failed to create window");
    glfwTerminate();
    return;
  }

  // Setting key callbacks
  glfwSetKeyCallback(window, &key_callback);

  glfwShowWindow(window);
  glfwMakeContextCurrent(window);

  // Turning on vsync
  glfwSwapInterval(1);

  // Reload after making context to use GL 3 core features
  DerelictGL3.reload();

  uint clear_color = rgbToUint(0, 128, 0);

  Buffer buffer;
  buffer.width = buffer_width;
  buffer.height = buffer_height;
  buffer.data = new uint[buffer.width * buffer.height];
  bufferClear(&buffer, clear_color);

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
  auto game = createGame(buffer_width, buffer_height);

  // Set Alien position
  for (size_t yi = 0; yi < 5; ++yi)
  {
    for (size_t xi = 0; xi < 11; ++xi)
    {
      auto alien = &game.aliens[yi * 11 + xi];
      alien.type = cast(ubyte) (5 - yi) / 2 + 1;

      alien.x = 16 * xi + 20;
      alien.y = 17 * yi + 128;
    }
  }

  auto death_counters = new ubyte[game.num_aliens];
  for (size_t i = 0; i < game.num_aliens; ++i)
  {
    death_counters[i] = 10;
  }

  // Main loop
  while (!glfwWindowShouldClose(window) && isRunning)
  {
    loopAnim(alienAnim);

    const auto newDir = playerDir * 2;

    if (newDir != 0)
    {
      if (game.player.x + playerSprite.width + newDir >= game.width)
      {
        game.player.x = game.width - playerSprite.width;
      }
      else if (cast (int)game.player.x + newDir <= 0)
      {
        game.player.x = 0;
      }
      else 
        game.player.x += newDir;
    }

    //glClear(GL_COLOR_BUFFER_BIT);
    bufferClear(&buffer, clear_color);

    for (size_t ai = 0; ai < game.num_aliens; ++ai)
    {
      if(!death_counters[ai]) 
        continue;
      
      const auto alien = &game.aliens[ai];

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

    for (size_t bi = 0; bi < game.num_bullets; ++bi)
    {
      const auto bullet = &game.bullets[bi];
      bufferDraw(&buffer, bulletSprite, bullet.x, bullet.y, rgbToUint(128, 0, 0));
    }

    // Simulate bullets
    for (size_t bi = 0; bi < game.num_bullets;)
    {
      game.bullets[bi].y += game.bullets[bi].dir;
      if (game.bullets[bi].y >= game.height ||
        game.bullets[bi].y < bulletSprite.height)
      {
          game.bullets[bi] = game.bullets[game.num_bullets - 1];
          --game.num_bullets;
          continue;
      }

      // Check hit
      for (size_t ai = 0; ai < game.num_aliens; ++ai)
      {
        const auto alien = &game.aliens[ai];
        if (alien.type == AlienType.ALIEN_DEAD) 
          continue;

        const auto animation = &alienAnim;
        size_t current_frame = animation.time / animation.frame_duration;
        const auto alien_sprite = &animation.frames[current_frame];
        bool overlap = overlapCheck(
          bulletSprite, game.bullets[bi].x, game.bullets[bi].y,
          *alien_sprite, alien.x, alien.y
        );
        
        if (overlap)
        {
          game.aliens[ai].type = AlienType.ALIEN_DEAD;
          // NOTE: Hack to recenter death sprite
          game.aliens[ai].x -= (alienAnim.frames[6].width - alien_sprite.width)/2;
          game.bullets[bi] = game.bullets[game.num_bullets - 1];
          --game.num_bullets;
          continue;
        }
      }
      
      ++bi;
    }

    bufferDraw(&buffer, playerSprite, game.player.x, game.player.y, rgbToUint(128, 0, 0));

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
    for (size_t ai = 0; ai < game.num_aliens; ++ai)
    {
      const auto alien = &game.aliens[ai];
      if (alien.type == AlienType.ALIEN_DEAD && death_counters[ai])
      {
        --death_counters[ai];
      }
    }

    // SImulate bullets
    if (firePressed && game.num_bullets < 128)
    {
      game.bullets[game.num_bullets].x = game.player.x + playerSprite.width / 2;
      game.bullets[game.num_bullets].y = game.player.y + playerSprite.height;
      game.bullets[game.num_bullets].dir = 2;
      ++game.num_bullets;
    }
    firePressed = false;
  }

  glDeleteVertexArrays(1, &fullscreen_triangle_vao);
  
  glfwDestroyWindow(window);
  glfwTerminate();
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
        isRunning = false;
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