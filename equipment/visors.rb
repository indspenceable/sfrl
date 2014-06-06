class ScentEnhancer < ItemBase
  attr_reader :duration
  def initialize
    @cost = 0 #rand(2)+1
    @duration = (rand(3) + 3) * 10
    @cooldown = rand(2) + 1
    @install_cost = rand(5)+1
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

class TerrainScanner < ItemBase
  attr_reader :max_range
  def initialize
    @cost = 0 #rand(2)+1
    @duration = (rand(3) + 3) * 10
    @max_range = 4 + rand(5)
    @install_cost = rand(5)+1
  end

  def use(stack, level, player)
    (player.x-max_range).upto(player.x+max_range) do |x|
      (player.y-max_range).upto(player.y+max_range) do |y|
        unless level.off_map?(x,y) || level.at(x,y).distance_to(player) > max_range
          level.scry_terrain(x,y)
        end
      end
    end
    stack
  end

  def pretty
    "Terrain Scanner"
  end

  def item_specific_description
    []
  end
end

class TerrainScanner < ItemBase
  attr_reader :max_range
  def initialize
    @cost = 0 #rand(2)+1
    @duration = (rand(3) + 3) * 10
    @max_range = 4 + rand(5)
    @install_cost = rand(5)+1
  end

  def use(stack, level, player)
    (player.x-max_range).upto(player.x+max_range) do |x|
      (player.y-max_range).upto(player.y+max_range) do |y|
        unless level.off_map?(x,y) || level.at(x,y).distance_to(player) > max_range
          level.scry_terrain(x,y)
        end
      end
    end
    stack
  end

  def pretty
    "Terrain Scanner"
  end

  def item_specific_description
    []
  end
end
