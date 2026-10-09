require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "la home muestra el workout del día" do
    get root_url
    assert_response :success
    assert_includes response.body, "Workout del día"
    assert_includes response.body, workouts(:one).title
  end

  test "páginas informativas y planes" do
    [ acerca_url, terminos_url, payments_new_url ].each do |url|
      get url
      assert_response :success
    end
  end
end
