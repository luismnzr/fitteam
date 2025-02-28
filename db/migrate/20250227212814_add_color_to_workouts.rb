class AddColorToWorkouts < ActiveRecord::Migration[7.2]
  def change
    add_column :workouts, :color, :string, default: '#004a37'
  end
end
