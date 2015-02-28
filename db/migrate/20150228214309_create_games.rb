class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :type
      t.string :board
      t.string :turn
      t.integer :status

      t.timestamps null: false
    end
  end
end
