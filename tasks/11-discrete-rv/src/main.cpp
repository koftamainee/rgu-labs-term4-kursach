#define IMGUI_APP_IMPL
#include "imgui_app.h"

#define DISCRETE_RANDOM_VARIABLE_IMPL
#include "discrete_random_variable.h"

#include <implot.h>

#include <vector>

int main()
{
  DiscreteRandomVariable rv({
      {1, 0.2},
      {2, 0.5},
      {3, 0.3}
  });

  ImGuiApp::init("Discrete RV Viewer");

  ImGuiApp::run([&]()
  {
      auto pmf = rv.pmf();
      auto cdf = rv.cdf();

      std::vector<double> x;
      std::vector<double> y_pmf;
      std::vector<double> y_cdf;

      x.reserve(pmf.size());
      y_pmf.reserve(pmf.size());
      y_cdf.reserve(cdf.size());

      for (const auto& [v, p] : pmf)
      {
          x.push_back(v);
          y_pmf.push_back(p);
      }

      for (const auto& f : cdf | std::views::values)
      {
          y_cdf.push_back(f);
      }

      ImGui::Text("E[X] = %.6f", rv.expectation());
      ImGui::Text("D[X] = %.6f", rv.variance());
      ImGui::Text("Skewness = %.6f", rv.skewness());
      ImGui::Text("Kurtosis = %.6f", rv.kurtosis());

      ImGui::Separator();

      if (ImPlot::BeginPlot("PMF"))
      {
        ImPlot::PlotBars("P(X)", x.data(), y_pmf.data(), static_cast<int>(x.size()), 0.6);
          ImPlot::EndPlot();
      }

      if (ImPlot::BeginPlot("CDF"))
      {
          ImPlot::PlotLine("F(X)", x.data(), y_cdf.data(), static_cast<int>(x.size()));
          ImPlot::EndPlot();
      }

      if (ImPlot::BeginPlot("Polyline"))
      {
          ImPlot::PlotLine("distribution", x.data(), y_pmf.data(), static_cast<int>(x.size()));
          ImPlot::EndPlot();
      }
  });

  ImGuiApp::shutdown();
}