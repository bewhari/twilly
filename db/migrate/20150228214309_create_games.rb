class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :sel
      t.string :board
      t.integer :turn
      t.integer :status

      t.timestamps null: false
    end
  end
end
