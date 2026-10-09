require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  test "toma el ID de cualquier link de YouTube" do
    {
      "dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtube.com/watch?feature=share&v=dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ?si=abc" => "dQw4w9WgXcQ",
      "https://www.youtube.com/embed/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "no es un video" => nil
    }.each do |input, expected|
      id = Workout.new(video_url: input).youtube_id
      expected ? assert_equal(expected, id, input) : assert_nil(id, input)
    end
  end

  test "guarda solo el ID" do
    workout = Workout.create!(title: "Nuevo", video_url: " https://youtu.be/dQw4w9WgXcQ ")
    assert_equal "dQw4w9WgXcQ", workout.video_url
  end

  test "la portada es la miniatura guardada o, si no hay, hqdefault" do
    workout = workouts(:one)
    assert_equal "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg", workout.cover_url
    workout.thumbnail_url = "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
    assert_equal "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg", workout.cover_url
  end

  test "cambiar el video borra la miniatura anterior" do
    workout = workouts(:one)
    workout.update!(thumbnail_url: "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    workout.update!(video_url: "https://youtu.be/ScMzIvxBSi4")
    assert_nil workout.thumbnail_url
    assert_equal "https://i.ytimg.com/vi/ScMzIvxBSi4/hqdefault.jpg", workout.cover_url
  end

  test "los videos viejos que no son de YouTube no impiden editar otros campos" do
    workout = workouts(:one)
    workout.update_column(:video_url, "video-viejo")
    assert workout.update(title: "Nuevo título")
  end
end
