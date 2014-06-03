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
    target.get_hit(2)
    player.cooldown += 1
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

  def title
    @delegate.title
  end

  def draw
    draw_title
    draw_map(0,1)
    draw_x_at(@x,@y+1)
    draw_status(WIDTH+1,0)
    Curses::refresh
  end

  def draw_x_at(x,y)
    Curses::setpos(y, x)
    if @delegate.valid?(@level, @level.map[@x][@y])
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
      if @delegate.valid?(@level, @level.map[@x][@y])
        return @delegate.continue(@prev, @player, @level.map[@x][@y])
      end
    end
    self
  end
end
