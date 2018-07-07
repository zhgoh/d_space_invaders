import derelict.glfw3.glfw3;
import derelict.opengl;
import std.experimental.logger;
import std.stdio;

version(Windows) string libName = "dlls\\glfw3.dll";
else string libName = "glfw3.so";

void main()
{
  DerelictGL3.load();
  DerelictGLFW3.load("dlls\\glfw3.dll");
  
  if (!glfwInit())
  {
    fatal("glfw failed to init");
    return;
  }
  
  auto window = glfwCreateWindow(640, 480, "Game", null, null);
  if(window is null)
  {
      fatal("glfw failed to create window");
      glfwTerminate();
      return;
  }

  glfwShowWindow(window);
  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);
  
  glViewport(0,0,640,480);
  glClearColor(0.39215686275, 0.58431372549, 0.92941176471, 1.0);

  while (!glfwWindowShouldClose(window))
  {
      glClear(GL_COLOR_BUFFER_BIT);
      glfwSwapBuffers(window);
      glfwPollEvents();
  }
  
  glfwDestroyWindow(window);
  glfwTerminate();
}
