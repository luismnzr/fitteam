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
      assert_equal expected, Workout.new(video_url: input).youtube_id, input
    end
  end

  test "guarda solo el ID" do
    workout = Workout.create!(title: "Nuevo", video_url: " https://youtu.be/dQw4w9WgXcQ ")
    assert_equal "dQw4w9WgXcQ", workout.video_url
  end
end
