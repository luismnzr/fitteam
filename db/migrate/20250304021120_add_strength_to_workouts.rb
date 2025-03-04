class AddStrengthToWorkouts < ActiveRecord::Migration[7.2]
  def change
    add_column :workouts, :strength, :boolean, default: false
  end
end
