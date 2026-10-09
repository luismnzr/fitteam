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

  test "el calendario solo recibe workouts con fecha y del rango visible" do
    get workouts_url(format: :json)
    ids = response.parsed_body.map { |e| e["id"] }
    assert_includes ids, @workout.id
    assert_not_includes ids, workouts(:two).id

    day = @workout.day
    get workouts_url(format: :json, start: (day + 10).iso8601, end: (day + 40).iso8601)
    assert_empty response.parsed_body

    get workouts_url(format: :json, start: "#{(day - 3).iso8601}T00:00:00-06:00", end: "#{(day + 3).iso8601}T00:00:00-06:00")
    assert_equal [ @workout.id ], response.parsed_body.map { |e| e["id"] }
  end

  test "las tarjetas usan la miniatura ligera y la página del workout la grande" do
    @workout.update_column(:thumbnail_url, "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    get lowerbody_url
    assert_includes response.body, "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
    assert_not_includes response.body, "maxresdefault"

    sign_in users(:member)
    get workout_url(@workout)
    assert_includes response.body, "maxresdefault"
  end

  test "la página de Strength muestra todos, no solo 10" do
    12.times { |i| Workout.create!(title: "Strength #{i}", video_url: "dQw4w9WgXcQ", strength: true) }
    get strength_url
    assert_select ".workoutCard", Workout.where(strength: true).count
  end
end
