class BasicLifeSupport
  def initialize
  end

  def cost
    1
  end

  def life_recovery
    7
  end

  def cooldown
    5
  end

  def use(stack, level, player)
    if player.energy >= cost
      old_energy = player.energy
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
