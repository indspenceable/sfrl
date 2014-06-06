class Mutant < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(rand(3), tile)
    @regen_cooldown = 0
  end

  def chr
    'm'
  end

  def color
    'green'
  end

  def act!(level, player)
    return unless awake?(level, player)
    2.times{ move_towards_player(level, player)  }
  end

  def attack_message
    "the mutant mangles you."
  end

  def describe
    "This mutant is weak, but it's extra legs allow it to move twice as fast as you."
  end
end
