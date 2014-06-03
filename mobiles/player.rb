class Player < MonsterBase
  attr_accessor :energy, :cooldown, :location, :messages
  attr_reader :hp, :cooldown
  def initialize(tile)
    super(7, tile)
    @energy = 3
    @cooldown = 0
    @messages = []
  end

  def heal!(x)
    @hp += x
    @hp = 10 if @hp>10
    @hp
  end

  def movement!(tile)
    move!(tile)
    wait(1)
  end

  def chr
    '@'
  end

  def attack(monster)
    wait(1)
    message!("You attack the #{monster.class.name}")
    monster.get_hit(1,self)
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

  def wait(x)
    @cooldown += x
  end
  def cool(x)
    @cooldown -= x
  end

  def message!(m)
    messages << m
  end
end
