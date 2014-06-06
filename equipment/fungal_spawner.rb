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
    "spawn where"
  end
end

class FungalSpawner < ItemBase
  attr_reader :cost, :max_distance, :cooldown, :install_cost
  def initialize
    @cost = rand(2)+1
    @max_distance = rand(3) + 3
    @cooldown = rand(2) + 1
    @install_cost = rand(5)+1
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
