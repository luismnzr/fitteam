require "test_helper"

class WorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workout = workouts(:one)
  end

  test "catálogo y páginas de categoría" do
    get workouts_url
    assert_response :success

    get abscore_url
    assert_response :success
    assert_includes response.body, workouts(:two).title
  end

  test "el JSON del calendario no expone el video" do
    get workouts_url(format: :json)
    assert_response :success
    event = response.parsed_body.find { |e| e["id"] == @workout.id }
    assert_equal @workout.title, event["title"]
    assert_nil event["video_url"]
    assert_not_includes response.body, @workout.video_url
  end

  test "sin plan se ve el aviso y no el video" do
    sign_in users(:guest)
    get workout_url(@workout)
    assert_response :success
    assert_includes response.body, "Necesitas un plan"
    assert_not_includes response.body, @workout.video_url
  end

  test "con acceso se ve el video y los comentarios con su autor" do
    sign_in users(:member)
    get workout_url(@workout)
    assert_response :success
    assert_includes response.body, %(data-vimeo-id="#{@workout.video_url}")
    assert_includes response.body, "Member Activa"
    assert_includes response.body, "Ana Gaby respondió"
  end

  test "las admins ven el video aunque no tengan suscripción" do
    sign_in users(:admin)
    get workout_url(@workout)
    assert_includes response.body, %(data-vimeo-id="#{@workout.video_url}")
    assert_includes response.body, edit_admin_workout_path(@workout)
  end

  test "el sitio público no permite crear, editar ni borrar workouts" do
    sign_in users(:member)
    assert_no_difference("Workout.count") do
      post "/workouts", params: { workout: { title: "Hack" } }
    end
    assert_response :not_found

    patch "/workouts/#{@workout.id}", params: { workout: { title: "Hack" } }
    assert_response :not_found
    delete "/workouts/#{@workout.id}"
    assert_response :not_found
    assert_equal "Pierna y glúteo", @workout.reload.title
  end

  test "favoritas pide sesión" do
    get favorites_url
    assert_redirected_to new_user_session_url

    sign_in users(:member)
    get favorites_url
    assert_response :success
  end
end
