class AddIndexToPlayersPhoneNum < ActiveRecord::Migration
  def change
    add_index :players, :phone_num, unique: true
  end
end
