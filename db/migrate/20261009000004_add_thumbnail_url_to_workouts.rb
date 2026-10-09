# Portada de cada workout: la miniatura de su video de YouTube (ya no se
# suben portadas a S3). Ver YoutubeThumbnail.
class AddThumbnailUrlToWorkouts < ActiveRecord::Migration[7.2]
  def change
    add_column :workouts, :thumbnail_url, :string
  end
end
