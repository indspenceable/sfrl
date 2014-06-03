class BootsValidator
  def initialize(boots, player)
    @boots = boots
    @player = player
  end
  def valid?(target)
    target.monster.nil? &&
    target.distance_to(@player.location) <= @boots.max_distance &&
    target.can_move_into?
  end
  def continue(prev, player, target)
    @boots.jump!(prev, @player, target)
  end
  def title
    "Jump destination"
  end
end

class BasicBoots
  def initialize
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
    end
  end

  def jump!(prev, player, target)
    player.move!(target)
    player.cooldown += 1
    prev
  end

  def pretty
    "jump boots"
  end
end