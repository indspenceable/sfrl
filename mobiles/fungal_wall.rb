class FungalWall < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(5, tile)
    @regen_cooldown = 0
    @next_regen = rand(5)+3
  end

  def chr
    'f'
  end

  def color
    'green'
  end

  def get_hit(a,player)
    super(a,player)
    @regen_cooldown = 0
  end

  def act!(_level, _player)
    @regen_cooldown += 1
    if @regen_cooldown == @next_regen
      @hp += 1
      @next_regen = rand(5)+3
      @hp = 5 if @hp > 5
    end
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
    @can_grow = true
  end

  def chr
    'f'
  end

  def color
    'magenta'
  end

  def act!(level, player)
    return unless awake?(level, player)
    @spread_cooldown += 1
    if @spread_cooldown >= 12 && @can_grow
      new_tile = [
        level.at(x+1, y),
        level.at(x-1, y),
        level.at(x, y+1),
        level.at(x, y-1),
      ].select(&:can_move_into?).shuffle.pop
      if new_tile
        self.class.new(new_tile, true)
        @can_grow = false
      end
      @spread_cooldown = 0
    elsif @spread_cooldown >= 45
      @can_grow = true
    end

  end

  def describe
    "once awoken, these nasty spores will spread until they cover this entire level of the ship."
  end
end

class SmellySpore < MonsterBase
  def initialize(tile, growing=false)
    super(1, tile)
  end

  def chr
    'f'
  end

  def color
    'yellow'
  end

  def die!(player)
    location.scent += 500
    super(player)
  end

  def act!(level, player)
    die!(player) if awake?(level, player) && location.distance_to(player)==1
  end

  def describe
    "once awoken or killed, these spores will explode, filling the air with a strong stench"
  end
end


