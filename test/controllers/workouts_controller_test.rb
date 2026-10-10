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
    assert_includes response.body, "Esta clase es parte de los planes de Fitteam"
    assert_not_includes response.body, @workout.video_url
  end

  test "con acceso se ve el video y los comentarios con su autor" do
    sign_in users(:member)
    get workout_url(@workout)
    assert_response :success
    assert_includes response.body, %(data-video-id="#{@workout.video_url}")
    assert_includes response.body, "Member Activa"
    assert_includes response.body, "Ana Gaby respondió"
  end

  test "las admins ven el video aunque no tengan suscripción" do
    sign_in users(:admin)
    get workout_url(@workout)
    assert_includes response.body, %(data-video-id="#{@workout.video_url}")
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

  test "el catálogo no expone los IDs de los videos (las miniaturas salen de la app)" do
    get workouts_url
    assert_response :success
    Workout.find_each { |w| assert_not_includes response.body, w.video_url }
    assert_not_includes response.body, "i.ytimg.com"
    assert_includes response.body, workout_thumbnail_path(@workout, size: :card).split("?").first
  end

  test "la miniatura se sirve desde la app, de la mejor que tenga el video, con caché larga" do
    @workout.update_column(:thumbnail_url, "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    requested = []
    YoutubeThumbnail.stub(:download, ->(url) { requested << url; "JPEG-#{url}" }) do
      get workout_thumbnail_url(@workout, size: "card", v: "1")
      assert_response :success
      assert_equal "image/jpeg", response.media_type
      assert_match "public", response.headers["Cache-Control"]
      assert_equal "JPEG-https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg", response.body

      get workout_thumbnail_url(@workout, size: "cover", v: "1")
      assert_equal "JPEG-https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg", response.body
    end
    assert_equal [ "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg" ] * 2, requested
  end

  test "si el workout no tiene su mejor miniatura, la busca la primera vez" do
    @workout.update_column(:thumbnail_url, nil)
    best = "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
    YoutubeThumbnail.stub(:fetch, ->(_) { best }) do
      YoutubeThumbnail.stub(:download, ->(url) { "JPEG-#{url}" }) do
        get workout_thumbnail_url(@workout, size: "cover")
      end
    end
    assert_equal "JPEG-#{best}", response.body
    assert_equal best, @workout.reload.thumbnail_url
  end

  test "si YouTube no da la miniatura responde 404 (el sitio muestra la portada genérica)" do
    YoutubeThumbnail.stub(:download, ->(_) { nil }) do
      get workout_thumbnail_url(@workout, size: "card")
    end
    assert_response :not_found
  end

  test "la página del workout usa la portada grande" do
    sign_in users(:member)
    get workout_url(@workout)
    assert_includes response.body, workout_thumbnail_path(@workout, size: :cover).split("?").first
  end

  test "la página de Strength muestra todos, no solo 10" do
    12.times { |i| Workout.create!(title: "Strength #{i}", video_url: "dQw4w9WgXcQ", strength: true) }
    get strength_url
    assert_select ".workoutCard", Workout.where(strength: true).count
  end
end
