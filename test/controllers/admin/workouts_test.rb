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
    fetched = nil
    fake_fetch = ->(id) { fetched = id; "https://i.ytimg.com/vi/#{id}/maxresdefault.jpg" }
    YoutubeThumbnail.stub(:fetch, fake_fetch) do
      assert_difference("Workout.count") do
        post admin_workouts_url, params: { workout: {
          title: "Glúteo con banda", video_url: "https://www.youtube.com/watch?v=jNQXAC9IVRw&t=10s",
          category: "Glutes and Hips", duration: "45min", intensity: "Alta",
          material: [ "", "Band", "Tapete" ], premiere: "1", strength: "1", day: "2026-11-02"
        } }
      end
    end
    workout = Workout.order(:id).last
    assert_redirected_to admin_workouts_url
    assert_equal "jNQXAC9IVRw", workout.video_url
    assert_equal "jNQXAC9IVRw", fetched
    assert_equal "https://i.ytimg.com/vi/jNQXAC9IVRw/maxresdefault.jpg", workout.cover_url
    assert_equal "Band, Tapete", workout.material
    assert workout.premiere?
    assert workout.strength?
    assert_equal Date.new(2026, 11, 2), workout.day
  end

  test "sin título no se guarda" do
    assert_no_difference("Workout.count") do
      post admin_workouts_url, params: { workout: { title: "", video_url: "jNQXAC9IVRw" } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Título no puede estar en blanco"
  end

  test "un link que no es de YouTube no se guarda" do
    assert_no_difference("Workout.count") do
      post admin_workouts_url, params: { workout: { title: "Vimeo", video_url: "https://vimeo.com/123456789" } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Video de YouTube no es un link de YouTube válido"
  end

  test "editar: quitar estreno y vaciar material sin volver a pedir la miniatura" do
    workout = workouts(:two)
    workout.update_column(:thumbnail_url, "https://i.ytimg.com/vi/ScMzIvxBSi4/maxresdefault.jpg")
    YoutubeThumbnail.stub(:fetch, ->(_) { flunk "no debería pedir la miniatura" }) do
      patch admin_workout_url(workout), params: { workout: { title: "Core 2.0", premiere: "0", material: [ "" ] } }
    end
    assert_redirected_to admin_workouts_url
    workout.reload
    assert_equal "Core 2.0", workout.title
    assert_not workout.premiere?
    assert_equal "", workout.material
    assert_equal "https://i.ytimg.com/vi/ScMzIvxBSi4/maxresdefault.jpg", workout.cover_url
  end

  test "cambiar el video cambia la portada" do
    workout = workouts(:two)
    workout.update_column(:thumbnail_url, "https://i.ytimg.com/vi/ScMzIvxBSi4/maxresdefault.jpg")
    YoutubeThumbnail.stub(:fetch, ->(id) { "https://i.ytimg.com/vi/#{id}/sddefault.jpg" }) do
      patch admin_workout_url(workout), params: { workout: { video_url: "https://youtu.be/M7lc1UVf-VE" } }
    end
    assert_equal "https://i.ytimg.com/vi/M7lc1UVf-VE/sddefault.jpg", workout.reload.cover_url
  end

  test "si YouTube no responde se usa hqdefault y se avisa" do
    YoutubeThumbnail.stub(:fetch, ->(_) { nil }) do
      post admin_workouts_url, params: { workout: { title: "Sin red", video_url: "jNQXAC9IVRw" } }
    end
    workout = Workout.order(:id).last
    assert_nil workout.thumbnail_url
    assert_equal "https://i.ytimg.com/vi/jNQXAC9IVRw/hqdefault.jpg", workout.cover_url
    assert_match "No pudimos comprobar la miniatura", flash[:notice]
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
