namespace :youtube do
  desc "Trae de YouTube la miniatura (portada) de los workouts que no la tienen. " \
       "FORCE=1 vuelve a pedirla para todos."
  task thumbnails: :environment do
    scope = ENV["FORCE"].present? ? Workout.all : Workout.where(thumbnail_url: [ nil, "" ])
    puts "Workouts a revisar: #{scope.count}"

    ok = 0
    missing = []
    scope.order(:id).find_each do |workout|
      url = YoutubeThumbnail.fetch(workout.youtube_id)
      if url
        workout.update_column(:thumbnail_url, url)
        ok += 1
      else
        missing << workout
      end
    end

    puts "✔ #{ok} workouts con miniatura de YouTube."
    if missing.any?
      puts "✘ #{missing.size} sin miniatura (link que no es de YouTube, video privado o borrado, o YouTube no respondió):"
      missing.each { |w| puts "  ##{w.id} #{w.title} (video: #{w.video_url.inspect})" }
    end
  end
end
