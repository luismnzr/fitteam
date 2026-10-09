require "test_helper"

class Admin::WorkoutsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "listado con búsqueda y filtros" do
    get admin_workouts_url(q: "core")
    assert_response :success
    assert_includes response.body, "Core de acero"
    assert_not_includes response.body, "Pierna y glúteo"

    get admin_workouts_url(filter: "premieres")
    assert_includes response.body, "Core de acero"
    assert_not_includes response.body, "Pierna y glúteo"

    get admin_workouts_url(filter: "scheduled", category: "Lower Body")
    assert_includes response.body, "Pierna y glúteo"
  end

  test "crear con link de YouTube, material, estreno y fecha" do
    assert_difference("Workout.count") do
      post admin_workouts_url, params: { workout: {
        title: "Glúteo con banda", video_url: "https://www.youtube.com/watch?v=jNQXAC9IVRw&t=10s",
        category: "Glutes and Hips", duration: "45min", intensity: "Alta",
        material: [ "", "Band", "Tapete" ], premiere: "1", strength: "1", day: "2026-11-02"
      } }
    end
    workout = Workout.order(:id).last
    assert_redirected_to admin_workouts_url
    assert_equal "jNQXAC9IVRw", workout.video_url
    assert_equal "Band, Tapete", workout.material
    assert workout.premiere?
    assert workout.strength?
    assert_equal Date.new(2026, 11, 2), workout.day
    assert_equal "https://i.ytimg.com/vi/jNQXAC9IVRw/hqdefault.jpg", workout.youtube_thumbnail_url
  end

  test "sin título no se guarda" do
    assert_no_difference("Workout.count") do
      post admin_workouts_url, params: { workout: { title: "", video_url: "jNQXAC9IVRw" } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Título no puede estar en blanco"
  end

  test "editar: quitar estreno, subir y quitar portada" do
    workout = workouts(:two)
    patch admin_workout_url(workout), params: { workout: {
      title: "Core 2.0", premiere: "0", material: [ "" ],
      cover: fixture_file_upload("cover.jpg", "image/jpeg")
    } }
    assert_redirected_to admin_workouts_url
    workout.reload
    assert_equal "Core 2.0", workout.title
    assert_not workout.premiere?
    assert_equal "", workout.material
    assert workout.cover.attached?

    patch admin_workout_url(workout), params: { workout: { title: "Core 2.0", remove_cover: "1" } }
    assert_not workout.reload.cover.attached?
  end

  test "eliminar borra sus comentarios y favoritas" do
    workout = workouts(:one)
    question_id = comments(:question).id
    assert_difference("Workout.count", -1) do
      assert_difference("Favorite.count", -1) do
        delete admin_workout_url(workout)
      end
    end
    assert_not Comment.exists?(question_id)
    assert_redirected_to admin_workouts_url
  end

  test "nuevo desde el calendario trae el día" do
    get new_admin_workout_url(day: "2026-12-01")
    assert_response :success
    assert_includes response.body, %(value="2026-12-01")
  end

  test "calendario por mes y mes inválido" do
    get admin_calendar_url(month: workouts(:one).day.strftime("%Y-%m"))
    assert_response :success
    assert_includes response.body, workouts(:one).title

    get admin_calendar_url(month: "basura")
    assert_response :success
  end
end
