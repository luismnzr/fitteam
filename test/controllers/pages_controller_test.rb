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

  test "los planes salen de Plan: visitantes, usuarios sin acceso y con acceso" do
    get payments_new_url
    assert_select ".plans_columns_card", Plan.all.size
    assert_select "a", text: "Suscribirme", count: Plan.all.size

    sign_in users(:guest)
    get root_url
    Plan.all.each do |plan|
      assert_select "form[action=?]", stripe_checkout_path(plan: plan.key)
      assert_includes response.body, plan.price
    end

    sign_in users(:member)
    get root_url
    assert_select ".plans", count: 0
  end

  test "el layout trae la imagen para compartir y el manifest de la app" do
    get root_url
    assert_select "meta[property='og:image'][content=?]", "#{root_url}og-image.jpg"
    get "/manifest.json"
    assert_equal "#f9f8f3", response.parsed_body["theme_color"]
    assert_equal [ "/icon-192.png", "/icon-512.png", "/icon-512.png" ], response.parsed_body["icons"].map { |i| i["src"] }
  end
end
