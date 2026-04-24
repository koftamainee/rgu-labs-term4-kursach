#pragma once

#include <functional>

class ImGuiApp
{
public:
    static void init(const char* title);
    static void run(const std::function<void()>& frame_func);
    static void shutdown();
};

#ifdef IMGUI_APP_IMPL

#include <stdexcept>

#include <GLFW/glfw3.h>

#include <imgui.h>
#include <implot.h>

#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

static GLFWwindow* g_window = nullptr;

static int g_width = 0;
static int g_height = 0;

void ImGuiApp::init(const char* title)
{
    if (!glfwInit())
    {
        throw std::runtime_error("glfw init failed");
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);

    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);

    g_width = mode->width;
    g_height = mode->height;

    g_window = glfwCreateWindow(
        g_width,
        g_height,
        title,
        nullptr,
        nullptr
    );

    if (!g_window)
    {
        throw std::runtime_error("window creation failed");
    }

    glfwSetWindowPos(g_window, 0, 0);

    glfwMakeContextCurrent(g_window);
    glfwSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImPlot::CreateContext();

    ImGui::StyleColorsDark();

    ImGui_ImplGlfw_InitForOpenGL(g_window, true);
    ImGui_ImplOpenGL3_Init("#version 330");
}

void ImGuiApp::run(const std::function<void()>& frame_func)
{
    while (!glfwWindowShouldClose(g_window))
    {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGuiIO& io = ImGui::GetIO();
        io.DisplaySize = ImVec2(static_cast<float>(g_width), static_cast<float>(g_height));

        frame_func();

        ImGui::Render();

        int fb_w = 0;
        int fb_h = 0;

        glfwGetFramebufferSize(g_window, &fb_w, &fb_h);

        glViewport(0, 0, fb_w, fb_h);
        glClear(GL_COLOR_BUFFER_BIT);

        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(g_window);
    }
}

void ImGuiApp::shutdown()
{
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();

    ImPlot::DestroyContext();
    ImGui::DestroyContext();

    glfwDestroyWindow(g_window);
    glfwTerminate();
}

#endif