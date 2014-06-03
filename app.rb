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
    ].shuffle.pop.new
  end

  def self.random_monster(tile)
    [
      Mutant,
      FungalWall,
      Bloat,
      SpreadingSpore,
      Hulk,
    ].shuffle.pop.new(tile)
  end

  def activate!(prev, level, player)
    case
    when @terrain == '<'
      prev
    when @terrain == '>'
      MainGame.new(player)
    when @item
      # item upgrade prompt
      # prev
      Equip.new(prev, level, player)
    end
  end

  attr_accessor :terrain, :item, :monster, :x, :y
  def initialize x, y, terrain
    @x, @y = x, y
    @terrain = terrain
    @item = nil
    @monster = nil
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

  def color
    if monster
      monster.color
    elsif item
      'bright_blue'
    else
      {
        '#' => 'blue',
        'E' => 'bright_yellow',
        '~' => 'bright_blue'
      }[terrain] || 'white'
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
    monster.nil? && %w(. < >).include?(terrain)
  end

  def block_los?
    %w(#).include?(terrain)
  end

  def bump!(player)
    case terrain
    when 'E'
      player.energy = 10
      @terrain = '.'
    end
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
    @level.calculate_los(@player.x, @player.y, 5)
    WIDTH.times do |x|
      HEIGHT.times do |y|
        Curses::setpos(y+offset_y,x+offset_x)
        if @level.lit?(x,y)
          draw_str(@level.map[x][y].chr, @level.map[x][y].color)
        elsif @level.memory(x,y)
          draw_str(@level.memory(x,y), 'bright_blackblack')
        else
          draw_str(" ", 'white')
        end
      end
    end
  end
  def draw_status(offset_x, offset_y)
    [
      "Commando",
      "hp: #{@player.hp}/10",
      "",
      "Energy: #{"*"*@player.energy}",
      "Radiation density: #{@level.radiation_pct}%",
      "",
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

require './equipment/phaser'
require './equipment/boots'
require './equipment/life_support'
require './mobiles/base'
require './mobiles/mutant'
require './mobiles/fungal_wall'
require './mobiles/bloat'
require './mobiles/hulk'
require './mobiles/player'

class MainGame < GameMode
  def initialize(pl=nil)
    @level = Level.new
    pl ||= begin
      p = Player.new(@level.find_terrain('<'))
      p.equip(1, BasicPhaser.new)
      p.equip(2, BasicBoots.new)
      p.equip(3, BasicLifeSupport.new)
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
    @level.process_radiation!
    monsters.each do |m|
      m.act!(@level, @player)
    end
    @player.cooldown -= 1
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
    case c
    when 'h'
      attempt_move(@level.map[@player.x-1][@player.y])
    when 'j'
      attempt_move(@level.map[@player.x][@player.y+1])
    when 'k'
      attempt_move(@level.map[@player.x][@player.y-1])
    when 'l'
      attempt_move(@level.map[@player.x+1][@player.y])
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
