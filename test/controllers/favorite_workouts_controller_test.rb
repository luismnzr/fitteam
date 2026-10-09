require "test_helper"

class FavoriteWorkoutsControllerTest < ActionDispatch::IntegrationTest
  test "agregar y quitar de favoritas" do
    sign_in users(:guest)
    workout = workouts(:two)

    assert_difference("Favorite.count") do
      post favorite_workouts_url(workout_id: workout.id)
      post favorite_workouts_url(workout_id: workout.id)
    end
    assert_includes users(:guest).favorite_workouts, workout

    assert_difference("Favorite.count", -1) do
      delete favorite_workout_url(workout)
    end
  end

  test "pide sesión" do
    post favorite_workouts_url(workout_id: workouts(:two).id)
    assert_redirected_to new_user_session_url
  end
end
