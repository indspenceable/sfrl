class Hulk < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(3,tile)
  end

  def chr
    'h'
  end

  def color
    'green'
  end

  def power
    3
  end

  def act!(level, player)
    move_towards_player(level, player) if level.lit?(x, y)
  end

  def attack(monster)
    super(monster)
  end

  def describe
    "This huge monster can take a beating, and dish it out as well. Beware!"
  end
end