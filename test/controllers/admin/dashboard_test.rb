require "test_helper"

class Admin::DashboardTest < ActionDispatch::IntegrationTest
  test "panel con métricas y la semana del calendario" do
    sign_in users(:admin)
    get admin_root_url
    assert_response :success
    assert_includes response.body, "Usuarios con acceso"
    assert_includes response.body, "Esta semana en el calendario"
    assert_includes response.body, workouts(:one).title
    assert_includes response.body, comments(:pending).text
  end
end
