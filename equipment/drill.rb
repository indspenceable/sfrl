class DrillValidator
  def initialize(drill, player)
    @drill = drill
    @player = player
  end
  def valid?(level, target)
    target.distance_to(@player.location) <= @drill.max_distance &&
    !target.can_move_into?
  end
  def continue(prev, player, level, target)
    @drill.drill!(prev, @player, level, target)
  end
  def title
    "What square would you like to drill?"
  end
end

class PowerDrill < ItemBase
  def initialize
  end

  def cost
    1
  end

  def max_distance
    1
  end

  def cooldown
    1
  end

  def install_cost
    1
  end

  def use(stack, level, player)
    if player.energy >= cost
      TargetSelector.new(stack, level, player, DrillValidator.new(self, player))
    else
      stack
    end
  end

  def drill!(prev, player, level, target)
    target.terrain = '.'
    player.wait(cooldown)
    player.energy -= cost
    prev
  end

  def pretty
    "Power Drill"
  end

  def item_specific_description
    # [["Range: #{max_distance}", 'white']]
    []
  end
end
