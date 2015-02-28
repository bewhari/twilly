require 'test_helper'

class PlayerTest < ActiveSupport::TestCase

  def setup
    @player = Player.new(name: "Example User", phone_num: "8478094004")
  end

  test "should be valid" do
    assert @player.valid?
  end

  test "name should be present" do
    @player.name = ""
    assert_not @player.valid?
  end

  test "phone_num should be present" do
    @player.phone_num = "     "
    assert_not @player.valid?
  end

  test "phone number should be unique" do
    duplicate_player = @player.dup
    @player.save
    assert_not duplicate_player.valid?
  end
end
