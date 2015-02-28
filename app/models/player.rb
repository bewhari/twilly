class Player < ActiveRecord::Base
  belongs_to :game

  validates :name,  presence: true
  validates :phone_num, presence: true, uniqueness: true

  def self.create_player(name, phone_num)
    return Player.new(name: name, phone_num: phone_num, game_id: 0)

=begin
    if @player.save
      return "New player"
    else
      return "Duplicate player"
    end
=end

  end

end
