class Hulk < MonsterBase
  attr_accessor :hp

  def initialize(tile)
    super(5,tile)
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
    return unless awake?(level, player)
    move_towards_player(level, player)
  end

  def attack_message
    "hulk smash"
  end

  def describe
    "This huge monster can take a beating, and dish it out as well. Beware!"
  end
end
