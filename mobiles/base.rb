class MonsterBase
  attr_reader :location
  def initialize(hp, location)
    @hp = hp
    @location = location
    @location.monster = self
  end

  def move!(tile)
    if @location
      @location.monster = nil
    end
    tile.monster = self
    @location = tile
  end

  def get_hit(damage)
    @hp -= damage
    die! if @hp <= 0
  end

  def power
    1
  end

  def attack(monster)
    monster.get_hit(power)
  end

  def x
    @location.x
  end

  def y
    @location.y
  end

  def movement!(tile)
    move!(tile)
  end

  def die!
    @location.monster = nil
  end


  def move_towards_player(level, player)
    dx = player.x - location.x
    dy = player.y - location.y
    ddx = dx == 0 ? 0 : (dx/dx.abs)
    ddy = dy == 0 ? 0 : (dy/dy.abs)
    if dx.abs + dy.abs == 1
      attack(player)
    elsif dx.abs >= dy.abs && level.at(location.x + ddx, location.y).can_move_into?
      move!(level.at(location.x + ddx, location.y))
    elsif level.at(location.x, location.y + ddy).can_move_into?
      move!(level.at(location.x, location.y + ddy))
    end
  end
end
