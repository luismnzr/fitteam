class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.integer :workout_id
      t.text :text
      
      t.timestamps
    end
  end
end
