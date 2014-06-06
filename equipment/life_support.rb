class BasicLifeSupport < ItemBase
  def initialize
  end

  def cost
    2
  end

  def life_recovery
    7
  end

  def cooldown
    3
  end

  def install_cost
    1
  end

  def use(stack, level, player)
    if player.energy >= cost
      old_energy = player.energy
      player.energy -= cost
      player.heal!(life_recovery)
      player.wait(cooldown)
      stack
    else
      stack
    end
  end

  def pretty
    "basic life support"
  end

  def item_specific_description
    []
  end
end
