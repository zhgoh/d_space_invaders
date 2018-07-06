import derelict.glfw3.glfw3;
import derelict.opengl;

// version(Windows) libName = "dlls\\glfw3.dll";
// else libName = "glfw3.so";

void main()
{
  DerelictGL3.load();
  DerelictGLFW3.load("dlls\\glfw3.dll");
  
  if (!glfwInit())
  {
    return;
  }
  
  auto window = glfwCreateWindow(640, 480, "Space Invaders", null, null);
  if(!window)
  {
      glfwTerminate();
      return;
  }
  glfwMakeContextCurrent(window);
  
  glClearColor(0.39215686275, 0.58431372549, 0.92941176471, 1.0);
  while (!glfwWindowShouldClose(window))
  {
      glClear(GL_COLOR_BUFFER_BIT);
      glfwSwapBuffers(window);
      glfwPollEvents();
  }
}
