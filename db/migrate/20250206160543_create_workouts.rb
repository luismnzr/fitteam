class CreateWorkouts < ActiveRecord::Migration[7.2]
  def change
    create_table :workouts do |t|
      t.string :title
      t.string :category
      t.string :duration
      t.string :video_url
      t.string :intensity
      t.string :material
      t.datetime :day

      t.timestamps
    end
  end
end
