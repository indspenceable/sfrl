require 'curses'
require 'pry'
require 'pry-debugger'
require './permissive_fov'
require 'set'

COLOR_IDS = {}
def c(i)
  COLOR_IDS[i] ||= begin
    (COLOR_IDS.values.max || 0)+1
  end
end
COLOR_ATTRS = {
  'bright' => Curses::A_BOLD,
}

WIDTH = 40
HEIGHT = 24

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
  def initialize x, y, terrain
    @x, @y = x, y
    @terrain = terrain
    @item = nil
    @monster = nil
    @scent = 0.0
  end
  def chr
    if monster
      monster.chr
    elsif item
      '~'
    else
      terrain
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
      when sms > 45
        'bright_magenta'
      when sms > 40
        'magenta'
      when sms > 35
        'bright_red'
      when sms > 30
        'red'
      when sms > 25
        'bright_green'
      when sms > 20
        'green'
      when sms > 15
        'bright_blue'
      when sms > 10
        'blue'
      when sms > 5
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
    (x-tile.x).abs + (y-tile.y).abs
  end
end

class Vault
  ORIENTATIONS = [0,1,2,3]
  def wildcards
    %w(?)
  end

  %w(all start).each do |m|
    define_singleton_method(m) do
      (@cache||={})[m] ||= File.read("./vaults/#{m}").split('~').map do |v|
        Vault.new(v.split.map{|str| str.split('')}).tap do |v|
          # v.variations.each(&:pp)
          # puts "-----"
        end
      end
    end
  end

  def pp
    @map.each do |row|
      puts row.join
    end
    puts "***"
  end

  def eql?(other)
    if other.is_a?(Vault)
      if width == other.width &&
        height == other.height
        width.times do |x|
          height.times do |y|
            return false unless map[x][y] == other.map[x][y]
          end
        end
        return true
      end
    else
      super(other)
    end
  end

  # def self.all
  #   @all_vaults ||= begin
  #     # Vault.new([%w(x $ x), %w(x . o), %w(x o x)]),
  #     # Vault.new([%w(x $ x), %w(x . x), %w(x . x), %w(x o x)]),
  #     # Vault.new([%w(x x x x x), %w( $ . . . .), %w(x x x x x)]),
  #     File.read('./vaults').split('~').map do |v|
  #       vu = Vault.new(v.split.map{|str| str.split('')})
  #     end
  #   end
  # end
  attr_reader :map
  def initialize raw_map
    # @@current_id ||= 0
    # @id = @current_id+=1
    @map = raw_map
    # width.times do |x|
    #   if @map[x][0] == '.'
    #     @map[x][0] = 'o'
    #   end
    #   if @map[x][height-1] == '.'
    #     @map[x][height-1] = 'o'
    #   end
    # end

    # height.times do |y|
    #   if @map[0][y] == '.'
    #     @map[0][y] = 'o'
    #   end
    #   if @map[width-1][y] == '.'
    #     @map[width-1][y] = 'o'
    #   end
    # end
  end

  def variations
    [0,1,2,3,4,5,6,7].map{|x| orient(x) }.uniq
  end

  def as_starting_vault
    orient(0).special('<')
  end

  def as_ending_vault
    orient(0).special('')
  end

  def orient o
    case o
    when 0
      Vault.new(Array.new(height) do |y|
        Array.new(width) do |x|
          @map[x][y]
        end
      end)
    when 1
      Vault.new(Array.new(height) do |y|
        Array.new(width) do |x|
          @map[width-x-1][y]
        end
      end)
      # reflected over x = -y
      # reflected = Array.new(@map.first.length) do |x|
      #   Array.new(@map.length) do |y|
      #     @map[y][x]
      #   end
      # end
      # Vault.new(reflected)

      #reflected on x axis
      # reflected = Array.new(width) do |x|
      #   Array.new(height) do |y|
      #     @map[x][height-y-1]
      #   end
      # end
      # # binding.prsy
      # Vault.new(reflected)
    when 2
      #reflected on y axis
      # reflected = Array.new(width) do |x|
      #   Array.new(height) do |y|
      #     @map[width-x-1][y]
      #   end
      # end
      # # binding.prsy
      # Vault.new(reflected)
      orient(1).orient(1)
    when 3
      orient(1).orient(1).orient(1)
    when 4
      # reflected on x axis
      reflected = Array.new(width) do |x|
        Array.new(height) do |y|
          @map[x][height-y-1]
        end
      end
      # binding.prsy
      Vault.new(reflected)
    when 5
      orient(1).orient(4)
    when 6
      orient(2).orient(4)
    when 7
      orient(3).orient(4)
    end
  end

  def width
    @map.length
  end

  def height
    @map.first.length
  end

  def oy
    @map.each do |column|
      if column.include?('$')
        return column.index('$')
      end
    end
    raise "no starting character in this vault."
  end

  def ox
    @map.each_with_index do |column,i|
      if column.include?('$')
        return i
      end
    end
    raise "no starting character in this vault."
  end
end

require './level'

class GameMode
  def draw_caption(x,y)
    Curses::setpos(y,x)
    draw_str(caption, 'white')
  end
  def draw_map(offset_x, offset_y)
    @level.calculate_los(@player)
    WIDTH.times do |x|
      HEIGHT.times do |y|
        Curses::setpos(y+offset_y,x+offset_x)
        if @level.lit?(x,y)
          draw_str(@level.map[x][y].chr, @level.map[x][y].color(@player))
        elsif @level.memory(x,y)
          draw_str(@level.memory(x,y), 'bright_blackblack')
        else
          draw_str(" ", 'white')
        end
      end
    end
  end

  def draw_message(lines, min_width=0)
    number_of_lines = lines.count+1
    # number_of_lines += 1 if number_of_lines.?
    box_width = lines.map(&:first).map(&:length).max+2
    box_width = min_width if box_width < min_width

    y_border = (HEIGHT - number_of_lines)/2
    y_border_bottom = y_border
    y_border_bottom -= 1 if lines.count.odd?
    x_border = (WIDTH  - box_width)/2

    (WIDTH-(2*x_border)).times do |x_|
      (HEIGHT-(y_border+y_border_bottom)).times do |y_|
        Curses::setpos(y_border + y_, x_border + x_)
        if x_ == 0 || x_ == WIDTH-(x_border*2)-1 || y_ == 0 || y_ == HEIGHT-(y_border+y_border_bottom)-1
          draw_str('*', 'white')
        else
          draw_str(' ', 'white')
        end
      end
    end

    lines.each_with_index do |(l, color),i|
      Curses::setpos(y_border + i + 1, x_border + 1)
      draw_str(l, color)
    end
  end
  def draw_status(offset_x, offset_y)
    [
      "Commando",
      "hp: #{@player.hp}/10",
      "",
      "level #{@level.difficulty}",
      "Energy: #{"*"*@player.energy}",
      "Radiation density: #{@level.radiation_pct}%",
      *([1,2,3,4,5].map do |i|
        if @player.item(i)
          "#{i}): #{@player.item(i).pretty}"
        else
          "#{i}): unequipped"
        end
      end),
      '',
      'hjkl: move',
      '12345: use item',
      '',
      *@player.messages.last(10)
    ].each_with_index do |(str, color),i|
      Curses::setpos(i+offset_y,offset_x)
      draw_str(str,color||'white')
    end
  end

  def draw_str(str, color_str)
    # binding.pry unless color
    *attrs, color = color_str.split('_')
    curses_attrs = 0

    attrs.each do |a|
      curses_attrs |= COLOR_ATTRS[a]
    end

    Curses::attron(Curses::color_pair(c(color)) | curses_attrs | Curses::A_NORMAL) do
      Curses::addstr(str||"")
    end
  end
end

require './equipment/item_base'
require './equipment/phaser'
require './equipment/boots'
require './equipment/life_support'
require './equipment/fungal_spawner'
require './equipment/drill'
require './equipment/visors'
require './mobiles/base'
require './mobiles/mutant'
require './mobiles/fungal_wall'
require './mobiles/bloat'
require './mobiles/hulk'
require './mobiles/player'

class MainGame < GameMode
  def difficulty
    @level.difficulty
  end
  def initialize(difficulty=0,pl=nil)
    @level = Level.new(difficulty)
    pl ||= begin
      p = Player.new(@level.find_terrain('<'))
      p.equip(1, BasicPhaser.new)
      p.equip(2, TerrainScanner.new)
      # p.equip(3, BasicLifeSupport.new)
      # p.equip(4, FungalSpawner.new)
      p.equip(5, ScentEnhancer.new)
      p
    end
    @player = pl
    @player.move!(@level.find_terrain('<'))
  end
  def should_process_input?
    !should_idle?
  end

  def caption
    @player.location.caption
  end

  def monsters
    WIDTH.times.map do |x|
      HEIGHT.times.map do |y|
        @level.map[x][y].monster
      end
    end.flatten.compact - [@player]
  end

  def idle!
    @level.process_radiation!(@player)
    @level.process_scent!(@player)

    monsters.each do |m|
      @level.calculate_los(m)
      m.act!(@level, @player)
    end
    @player.cool(1)
    self
  end
  def should_idle?
    @player.cooldown > 0
  end
  def draw
    # draw_title
    draw_map(0,0)
    draw_caption(0,24)
    draw_status(WIDTH+1, 0)
    Curses::refresh
  end

  def process_input! c
    @level.calculate_los(@player)
    case c
    when 'h'
      attempt_move(@level.map[@player.x-1][@player.y])
    when 'j'
      attempt_move(@level.map[@player.x][@player.y+1])
    when 'k'
      attempt_move(@level.map[@player.x][@player.y-1])
    when 'l'
      attempt_move(@level.map[@player.x+1][@player.y])
    when '.'
      @player.wait(1)
    when 'd'
      return DescribeMode.new(self, @level, @player)
    when '?'
      # TODO - info mode.
    when 'a'
      rtn = @player.location.activate!(self, @level, @player)
      return rtn if rtn
    else
      if %w(1 2 3 4 5).include?(c)
        return @player.item(c.to_i).use(self, @level, @player) if @player.item(c.to_i)
      end
    end
    self
  end

  def attempt_move(tile)
    if tile.can_move_into?
      @player.movement!(tile)
    elsif tile.monster
      @player.attack(tile.monster)
    else
      tile.bump!(@player)
    end
  end
end

class MessageWindow < GameMode
  def initialize(stack, level, player, message)
    @prev, @level, @player, @message = stack, level, player, message
  end

  def draw
    draw_map(0,0)
    draw_caption(0,24)
    draw_status(WIDTH+1, 0)
    draw_message(@message)
    Curses::refresh
  end

  def should_idle?
    false
  end

  def should_process_input?
    true
  end

  def process_input! c
    @prev
  end

  def caption
    ""
  end
end

class DescribeMode < GameMode
  def initialize(stack, level, player)
    @prev, @level, @player = stack, level, player
  end
  def draw
    draw_map(0,0)
    draw_caption(0,24)
    draw_status(WIDTH+1, 0)
    draw_message(prompt)
    Curses::refresh
  end

  def caption
    "describe what?"
  end

  def prompt
    things_to_describe = []
    %w(1 2 3 4 5).each do |i|
      if @player.item(i.to_i)
        things_to_describe << "#{i}) #{@player.item(i.to_i).pretty}"
      end
    end
    if @player.location.item
      ".) #{@player.location.item.pretty}"
    end
    if things_to_describe.any?
      ["Describe what?"] + things_to_describe
    else
      ["Nothing to describe."]
    end.map do |l|
      [l, 'white']
    end
  end

  def should_idle?
    false
  end
  def should_process_input?
    true
  end

  def process_input! c
    if %w(1 2 3 4 5).include?(c)
      if @player.item(c.to_i)
        return MessageWindow.new(self, @level, @player, @player.item(c.to_i).long_description)
      end
      self
    elsif c == '.' && @player.location.item
      return MessageWindow.new(self, @level, @player, @player.location.item.long_description)
    elsif c == 'q'
      return @prev
    end
  end
end

m = MainGame.new
Curses::init_screen
begin
  Curses::cbreak
  Curses::noecho
  Curses::refresh
  Curses::start_color

  # INIT colors
  Curses::init_pair(c('white'),Curses::COLOR_WHITE,Curses::COLOR_BLACK)
  # COLOR_ATTRS['white'] = Curses::A_BOLD
  Curses::init_pair(c('blue'),Curses::COLOR_BLUE,Curses::COLOR_BLACK)
  Curses::init_pair(c('red'),Curses::COLOR_RED,Curses::COLOR_BLACK)
  Curses::init_pair(c('green'),Curses::COLOR_GREEN,Curses::COLOR_BLACK)
  Curses::init_pair(c('black'),Curses::COLOR_BLACK,Curses::COLOR_BLACK)
  # COLOR_ATTRS['black'] = Curses::A_BOLD
  Curses::init_pair(c('yellow'),Curses::COLOR_YELLOW,Curses::COLOR_BLACK)
  # COLOR_ATTRS['yellow'] = Curses::A_BOLD
  Curses::init_pair(c('magenta'),Curses::COLOR_MAGENTA,Curses::COLOR_BLACK)

  current_action = m
  Curses::curs_set(0)

  loop do
    Curses::clear
    current_action.draw
    current_action = current_action.process_input!(Curses::getch) if current_action.should_process_input?
    current_action = current_action.idle! if current_action.should_idle?
  end
ensure
  Curses::close_screen
end
