class BasicLifeSupport
  def initialize
  end

  def cost
    2
  end

  def life_recovery
    1
  end

  def cooldown
    3
  end

  def use(stack, level, player)
    if player.energy >= cost
      player.energy -= cost
      player.heal!(life_recovery)
      player.cooldown += cooldown
      stack
    else
      stack
    end
  end

  def pretty
    "basic life support"
  end
end
