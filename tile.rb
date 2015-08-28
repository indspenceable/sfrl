class Tile
  def self.build(x, y, c)
    case c
    when '~'
      t = Tile.new(x, y, '.')
      t.item = random_item(t)
      t
    when 'x'
      t = Tile.new(x, y, '.')
      t.monster = random_monster(t)
      t
    else
      Tile.new(x, y, c)
    end
  end

  def self.random_item(tile)
    [
      BasicPhaser,
      BasicBoots,
      BasicLifeSupport,
      FungalSpawner,
      ScentEnhancer,
      PowerDrill,
      TerrainScanner,
    ].shuffle.pop.new
  end

  def self.random_monster(tile)
    [
      Mutant,
      FungalWall,
      Bloat,
      SpreadingSpore,
      SmellySpore,
      Hulk,
    ].shuffle.pop.new(tile)
  end

  def activate!(prev, level, player)
    case
    when @terrain == '<'
      player.message!("it's dangerous to go back")
      prev
    when @terrain == '>'
      player.message!("you walk down the stairs")
      MainGame.new(level.difficulty+1, player)
    when @terrain == 'E'
      energy_gain = rand(5)-1
      energy_gain = 1 if energy_gain < 1
      player.message!("you draw some energy (#{energy_gain}) from the",
                      "outlet, before it goes dark.")
      player.energy += energy_gain
      @terrain = '.'
      player.wait(1)
      prev
    when @item
      # item upgrade prompt
      # prev
      Equip.new(prev, level, player)
    end
  end

  attr_accessor :terrain, :item, :monster, :x, :y, :scent
  attr_reader :destination_for
  def initialize x, y, terrain
    @x, @y = x, y
    @terrain = terrain
    @item = nil
    @monster = nil
    @scent = 0.0
    @destination_for = []
  end
  def chr
    if monster
      monster.chr
    elsif item
      '~'
    else
      if @destination_for.any? && terrain == '.'
        '*'
      else
        terrain
      end
    end
  end

  def color(player)
    if monster
      monster.color
    elsif item
      'bright_blue'
    else
      {
        '#' => 'blue',
        'E' => 'bright_yellow',
        '~' => 'bright_blue'
      }[terrain] || color_by_scent(player)
    end
  end

  def color_by_scent(player)

    if player.can_see_scent?
      sms = (100*scent)/Level::MAX_SCENT
      case
      when sms > 90
        'bright_magenta'
      when sms > 80
        'magenta'
      when sms > 70
        'bright_red'
      when sms > 60
        'red'
      when sms > 50
        'bright_green'
      when sms > 40
        'green'
      when sms > 30
        'bright_blue'
      when sms > 20
        'blue'
      when sms > 10
        'bright_white'
      else
        'white'
      end
    else
      if distance_to(player.location) <= 2
        case
        when scent > 150
          'bright_magenta'
        when scent > 100
          'magenta'
        else
          'white'
        end
      else
        'white'
      end
    end
  end

  def caption
    if @item
      "You see: #{@item.pretty}."
    elsif @terrain == '>'
      "there is a staircase down here."
    elsif @terrain == '<'
      "there is a staircase up here."
    else
      ""
    end
  end

  def can_move_into?
    monster.nil? && %w(. < > E).include?(terrain)
  end

  def block_scent?
    %w(#).include?(terrain)
  end

  def block_los?
    %w(#).include?(terrain)
  end

  def bump!(player)
  end

  def distance_to(tile)
    ((x-tile.x)**2 + (y-tile.y)**2)**0.25
  end
end
