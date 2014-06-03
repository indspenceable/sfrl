class FungalWall < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(1, tile)
    @regen_cooldown = 0
  end

  def chr
    'f'
  end

  def color
    if @hp >= 2
      'green'
    else
      'bright_green'
    end
  end

  def get_hit(a)
    super(a)
    @regen_cooldown = 0
  end

  def act!(_level, _player)
    @regen_cooldown += 1
    @hp = 2 if @regen_cooldown == 3
  end

  def describe
    "while not strictly harmful, this fungus will regenerate if you don't kill it quickly"
  end
end

class SpreadingSpore < MonsterBase
  def initialize(tile, growing=false)
    super(1, tile)
    @spread_cooldown = 0
    @seen = growing
  end

  def chr
    'f'
  end

  def color
    'bright_black'
  end

  def act!(level, _player)
    return unless (@seen ||= level.lit?(x, y))
    @spread_cooldown += 1
    if @spread_cooldown >= 12
      new_tile = [
        level.at(x+1, y),
        level.at(x-1, y),
        level.at(x, y+1),
        level.at(x, y-1),
      ].select(&:can_move_into?).shuffle.pop
      if new_tile
        self.class.new(new_tile, true)
      end
      @spread_cooldown = 0
    end
  end

  def describe
    "once awoken, these nasty spores will spread until they cover this entire level of the ship."
  end
end
