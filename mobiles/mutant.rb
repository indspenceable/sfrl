class Mutant < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(1, tile)
    @regen_cooldown = 0
  end

  def chr
    'm'
  end

  def color
    'green'
  end

  def act!(level, player)
    # only act if we're in line of sight.
    2.times{ move_towards_player(level, player) if level.lit?(x, y) }
  end

  def describe
    "This mutant is weak, but it's extra legs allow it to move twice as fast as you."
  end
end
