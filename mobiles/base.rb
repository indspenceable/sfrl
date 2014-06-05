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

  def get_hit(damage, player)
    @hp -= damage
    die!(player) if @hp <= 0
  end

  def power
    1
  end

  def scent_threshold
    100
  end

  def sight_chance
    5
  end

  def awake?(level, player)
    @awake ||= rand(100) < (100*location.scent/scent_threshold) ||
      can_see_player?(level, player) && rand(100) < sight_chance
  end

  def can_see_player?(level, player)
    level.lit?(player.x, player.y)
  end

  def attack(player)
    player.message!(attack_message)
    player.get_hit(power, player)
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

  def die!(player)
    player.message!("The #{self.class.name} dies.")
    @location.monster = nil
  end

  def move_towards_player(level, player)
    if can_see_player?(level, player)
      move_towards_seen_player(level, player)
    else
      move_by_scent(level, player)
    end
  end

  def move_towards_seen_player(level, player)
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
    elsif level.at(location.x + ddx, location.y).can_move_into?
      move!(level.at(location.x + ddx, location.y))
    end
  end

  def move_by_scent(level, player)
    dest = [
      level.at(x+1, y),
      level.at(x-1, y),
      level.at(x, y-1),
      level.at(x, y+1),
    ].select{|t| t.can_move_into?}.sort_by(&:scent).last
    if dest.monster == player
      attack(player)
    else
      move!(dest)
    end
  end
end
