json.array!(@workouts) do |workout|
  json.extract! workout, :id, :title
  json.start workout.day
  json.color workout.color
  json.url workout_url(workout, format: :html)
end
