# Los comentarios no guardaban quién los escribió. Ahora llevan su autor
# (user_id) y las respuestas de Ana Gaby desde el admin cuelgan del
# comentario original (parent_id). Los comentarios viejos quedan sin autor.
class AddUserAndParentToComments < ActiveRecord::Migration[7.2]
  def change
    add_reference :comments, :user, foreign_key: { on_delete: :nullify }
    add_reference :comments, :parent, foreign_key: { to_table: :comments, on_delete: :cascade }
  end
end
