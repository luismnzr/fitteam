require "test_helper"

class Admin::AccessTest < ActionDispatch::IntegrationTest
  PAGES = %w[/admin /admin/workouts /admin/workouts/new /admin/calendario /admin/users /admin/comments].freeze

  test "sin sesión manda a iniciar sesión" do
    get "/admin"
    assert_redirected_to new_user_session_url
  end

  test "usuarias que no son admin no entran" do
    sign_in users(:member)
    PAGES.each do |path|
      get path
      assert_redirected_to root_url, "#{path} debería redirigir"
    end
    post admin_workouts_url, params: { workout: { title: "Hack", video_url: "dQw4w9WgXcQ" } }
    assert_redirected_to root_url
    assert_not Workout.exists?(title: "Hack")
  end

  test "las admins ven todas las secciones" do
    sign_in users(:admin)
    PAGES.each do |path|
      get path
      assert_response :success, "#{path} debería cargar"
    end
    get admin_user_url(users(:member))
    assert_response :success
    get edit_admin_user_url(users(:member))
    assert_response :success
    get edit_admin_workout_url(workouts(:one))
    assert_response :success
  end
end
