class Player < MonsterBase
  attr_accessor :energy, :cooldown, :location, :messages, :can_see_scent
  attr_reader :hp, :cooldown
  def initialize(tile)
    super(7, tile)
    @energy = 3
    @cooldown = 0
    @messages = []
    @can_see_scent = 0
  end

  def heal!(x)
    @hp += x
    @hp = 10 if @hp>10
    @hp
  end

  def recharge(x)
    @energy += x
    @energy = 10 if @energy > 10
  end

  def movement!(tile)
    move!(tile)
    wait(1)
  end

  def can_see_scent?
    @can_see_scent > 0
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
    @can_see_scent -= 1 if @can_see_scent > 0
  end
  def cool(x)
    @cooldown -= x
  end

  def message!(*ms)
    ms.each do |m|
      messages << m
    end
  end
end
