class ChangeDayToDateInWorkouts < ActiveRecord::Migration[7.2]
  def change
    change_column :workouts, :day, :date
  end
end