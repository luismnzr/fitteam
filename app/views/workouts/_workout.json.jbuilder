json.extract! workout, :id, :title, :category, :duration, :video_url, :intensity, :material, :day, :created_at, :updated_at
json.url workout_url(workout, format: :json)
