class BootsValidator
  def initialize(boots, player)
    @boots = boots
    @player = player
  end
  def valid?(level, target)
    level.lit?(target.x, target.y) &&
    target.monster.nil? &&
    target.distance_to(@player.location) <= @boots.max_distance &&
    target.can_move_into?
  end
  def continue(prev, player, level, target)
    @boots.jump!(prev, @player, target)
  end
  def title
    "Jump destination"
  end
end

class BasicBoots < ItemBase
  def initialize
  end

  def cooldown
    1
  end

  def cost
    1
  end

  def max_distance
    4
  end

  def use(stack, level, player)
    if player.energy >= cost
      TargetSelector.new(stack, level, player, BootsValidator.new(self, player))
    else
      stack
    end
  end

  def jump!(prev, player, target)
    player.energy -= cost
    player.move!(target)
    player.wait(cooldown)
    prev
  end

  def pretty
    "jump boots"
  end

  def item_specific_description
    [["Range: #{max_distance}", 'white']]
  end

end
