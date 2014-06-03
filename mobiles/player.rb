class Player < MonsterBase
  attr_accessor :energy, :cooldown, :location
  attr_reader :hp
  def initialize(tile)
    super(7, tile)
    @energy = 3
    @cooldown = 0
  end

  def heal!(x)
    @hp += x
    @hp = 10 if @hp>10
    @hp
  end

  def movement!(tile)
    move!(tile)
    @cooldown += 1
  end

  def chr
    '@'
  end

  def attack(monster)
    monster.get_hit(1)
    @cooldown += 1
  end

  def color
    'white'
  end

  def item(slot)
    @items ||= {}
    @items[slot]
  end

  def equip(slot, item)
    @items ||= {}
    @items[slot] = item
  end
end
