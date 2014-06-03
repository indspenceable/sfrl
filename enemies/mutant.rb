class Mutant
  attr_accessor :hp

  def initialize(tile)
    @location = tile
    tile.monster = self
    @hp = 2
    @regen_cooldown = 0
  end

  def chr
    if @hp >=2
      '8'
    else
      'o'
    end
  end

  def color
    'bright_green'
  end

  def hit(a)
    @hp -= 1
    @regen_cooldown = 0
  end

  def move!
    @regen_cooldown += 1
    @hp = 2 if @regen_cooldown == 3
  end

  def die!
    @location.monster = nil
  end
end
