# Índices para las consultas de todos los días: comentarios de un workout
# (su página), workouts por día (home y calendario) y favoritas únicas (el
# mismo workout no se puede guardar dos veces; antes de crear el índice se
# borran los duplicados que ya existan, conservando el más antiguo).
class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def up
    add_index :comments, :workout_id
    add_index :workouts, :day

    execute <<~SQL
      DELETE FROM favorites
      WHERE id NOT IN (
        SELECT MIN(id) FROM favorites GROUP BY user_id, favorited_type, favorited_id
      )
    SQL
    add_index :favorites, [ :user_id, :favorited_type, :favorited_id ], unique: true, name: "index_favorites_uniqueness"
    # El índice único empieza por user_id, así que el de user_id solo sobra.
    remove_index :favorites, :user_id
  end

  def down
    add_index :favorites, :user_id
    remove_index :favorites, name: "index_favorites_uniqueness"
    remove_index :workouts, :day
    remove_index :comments, :workout_id
  end
end
