class PhaserValidator
  def initialize(phaser)
    @phaser = phaser
  end
  def valid?(level, target)
    level.lit?(target.x, target.y) &&
    target.monster &&
    !target.monster.is_a?(Player)
  end
  def continue(prev, player, target)
    @phaser.fire!(prev, player, target.monster)
  end
  def title
    "Phaser target select"
  end
end

class BasicPhaser
  attr_reader :shots
  def initialize
    @shots = 10
  end

  def use(stack, level, player)
    if @shots > 0
      TargetSelector.new(stack, level, player, PhaserValidator.new(self))
    else
      stack
    end
  end

  def fire!(prev, player, target)
    @shots-=1
    player.message!("You shoot the #{target.class.name}")
    target.get_hit(2, player)
    player.wait(1)
    return prev
  end

  def pretty
    "phaser (shots: #{@shots})"
  end
end

class TargetSelector < GameMode
  def initialize(stack, level, player, delegate)
    @prev = stack
    @level = level
    @player = player
    @delegate = delegate
    @x, @y = player.x, player.y
  end
  def should_idle?
    false
  end
  def should_process_input?
    true
  end

  def caption
    if currently_valid?
      ""
    else
      "invalid"
    end
  end

  def draw
    draw_map(0,0)
    draw_x_at(@x,@y)
    draw_caption(0,24)
    draw_status(WIDTH+1,0)
    Curses::refresh
  end

  def currently_valid?
    @delegate.valid?(@level, @level.map[@x][@y])
  end

  def draw_x_at(x,y)
    Curses::setpos(y, x)
    if currently_valid?
      draw_str("X",'red')
    else
      draw_str("X",'blue')
    end
  end

  def process_input! c
    case c
    when 'h'
      @x-=1
    when 'j'
      @y+=1
    when 'k'
      @y-=1
    when 'l'
      @x+=1
    when 'q'
      return @prev
    when ' '
      if currently_valid?
        return @delegate.continue(@prev, @player, @level.map[@x][@y])
      end
    end
    self
  end
end


class Equip < GameMode
  def initialize(stack, level, player)
    @prev = stack
    @level = level
    @player = player
  end
  def should_idle?
    false
  end
  def should_process_input?
    true
  end

  def caption
    "Select what slot to equip #{@player.location.item.pretty}"
  end

  def draw
    draw_map(0,0)
    draw_caption(0,24)
    draw_status(WIDTH+1,0)
    Curses::refresh
  end

  def process_input! c
    if %w(1 2 3 4 5).include?(c)
      @player.equip(c.to_i, @player.location.item)
      @player.location.item = nil
      return @prev
    elsif c == 'q'
      return @prev
    end

    self
  end
end
