class FungalValidator
  def initialize(phaser, player)
    @phaser = phaser
    @player = player
  end
  def valid?(level, target)
    level.lit?(target.x, target.y) &&
    target.monster.nil? &&
    target.distance_to(@player.location) <= @phaser.max_distance &&
    target.can_move_into?
  end
  def continue(prev, player, level, target)
    @phaser.fire!(prev, @player, level, target)
  end
  def title
    "Jump destination"
  end
end

class FungalSpawner < ItemBase
  def initialize
  end

  def cost
    3
  end

  def max_distance
    5
  end

  def cooldown
    1
  end

  def use(stack, level, player)
    if player.energy >= cost
      TargetSelector.new(stack, level, player, FungalValidator.new(self, player))
    else
      stack
    end
  end

  def fire!(prev, player, level, target)
    ([
        level.at(target.x - 1, target.y),
        level.at(target.x + 1, target.y),
        level.at(target.x, target.y - 1),
        level.at(target.x, target.y + 1),
      ].select{|t| t.can_move_into? && rand(2)==0} + [target]).each do |t|
      if t.monster.nil?
        [SpreadingSpore, FungalWall].shuffle.pop.new(t)
      end
    end
    player.wait(cooldown)
    player.energy -= cost
    prev
  end

  def pretty
    "Fungal Spawner"
  end

  def item_specific_description
    [["Range: #{max_distance}", 'white']]
  end
end

class ScentEnhancer < ItemBase
  def initialize
  end

  def cost
    1
  end

  def cooldown
    1
  end

  def duration
    50
  end

  def use(stack, level, player)
    if player.energy >= cost
      player.can_see_scent += 50
      player.wait(cooldown)
      player.energy -= cost
      stack
    else
      stack
    end
  end

  def pretty
    "Scent Enhancer"
  end

  def item_specific_description
    [["Duration: #{duration}", 'white']]
  end

end
