class Bloat< MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(1,tile)
  end

  def chr
    'b'
  end

  def color
    'magenta'
  end

  def power
    5
  end

  def act!(level, player)
    move_towards_player(level, player) if level.lit?(x, y)
  end

  def attack(monster)
    super(monster)
    die!
  end

  def describe
    "this bloated monstrosity will explode if you give it the chance, dealing heavy damage."
  end
end
