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
    20
  end

  def awake?(level, player)
    @awake ||= rand(100) < (100*location.scent/scent_threshold) ||
      can_see_player?(level, player) &&
      rand(100) > (sight_chance * location.distance_to(player.location)**(0.25))
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
    if location.distance_to(player) == 1
      attack(player)
    elsif can_see_player?(level, player)
      move_towards_seen_player(level, player)
    else
      move_by_scent(level, player)
    end
  end

  def move_towards_seen_player(level, player)
    move_towards(level, player)
  end

  def move_towards(level, obj)
    dx = obj.x - location.x
    dy = obj.y - location.y
    ddx = dx == 0 ? 0 : (dx/dx.abs)
    ddy = dy == 0 ? 0 : (dy/dy.abs)
    if dx.abs >= dy.abs && level.at(location.x + ddx, location.y).can_move_into?
      move!(level.at(location.x + ddx, location.y))
    elsif level.at(location.x, location.y + ddy).can_move_into?
      move!(level.at(location.x, location.y + ddy))
    elsif level.at(location.x + ddx, location.y).can_move_into?
      move!(level.at(location.x + ddx, location.y))
    end
  end

  def move_by_scent(level, player)
    possible_spaces = []
    WIDTH.times do |w|
      HEIGHT.times do |h|
        # TODO this should be "SCENT LOS to."
        if level.lit?(w, h) && level.at(w,h).can_move_into?
          possible_spaces << level.at(w,h)
        end
      end
    end
    move_towards(level, possible_spaces.sort_by(&:scent).last)

    # dest = [
    #   level.at(x+1, y),
    #   level.at(x-1, y),
    #   level.at(x, y-1),
    #   level.at(x, y+1),
    # ].select{|t| t.can_move_into?}.sort_by(&:scent).last
    # return unless dest
    # if dest.monster == player
    #   attack(player)
    # else
    #   move!(dest)
    # end
  end
end
