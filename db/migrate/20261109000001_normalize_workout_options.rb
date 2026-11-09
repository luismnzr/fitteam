# Deja una sola versión de cada grupo muscular, duración, intensidad y
# material ("LOWER BODY", "AbS and Core" -> "Lower Body", "ABS and Core";
# "45", "45:00" -> "45min"; "60", "60 min" -> "1 hora"). Los que no se
# reconocen se quedan como están y se listan en la salida.
class NormalizeWorkoutOptions < ActiveRecord::Migration[7.2]
  def up
    Workout.reset_column_information
    Workout.find_each do |workout|
      workout.send(:normalize_options)
      changes = workout.changes.transform_values(&:last)
      workout.update_columns(changes) if changes.any?
    end

    { category: Workout::CATEGORIES, duration: Workout::DURATIONS, intensity: Workout::INTENSITIES }.each do |column, options|
      unknown = Workout.where.not(column => options + [ nil, "", "-" ]).distinct.pluck(column)
      say "#{column}: sin reconocer #{unknown.inspect}" if unknown.any?
    end
  end

  def down
    # Los valores viejos eran variantes de los mismos; no hay a qué volver.
  end
end
