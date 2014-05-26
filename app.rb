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
COLOR_ATTRS = {}

WIDTH = 40
HEIGHT = 20

class Tile
  def self.build(x, y, c)
    case c
    when '*'
      Tile.new(x, y, '.', random_item, nil)
    when 'x'
      Tile.new(x, y, '.', nil, random_monster)
    else
      Tile.new(x, y, c, nil, nil)
    end
  end
  def self.random_item
    nil
  end

  def self.random_monster
    nil
  end

  attr_accessor :terrain, :item, :monster, :x, :y
  def initialize x, y, terrain, item, monster
    @x, @y = x, y
    @terrain = terrain
    @item = item
    @monster = monster
  end
  def chr
    if monster
      monster.chr
    elsif item
      item.chr
    else
      terrain
    end
  end

  def can_move_into?
    monster.nil? && %w(. <).include?(terrain)
  end

  def block_los?
    %w(# [).include?(terrain)
  end

  def bump!(player)
    case terrain
    when '['
      player.energy += 1
      @terrain = '#'
    end
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

class Level
  include PermissiveFieldOfView
  def initialize
    @map = Array.new(WIDTH) do |x|
      Array.new(HEIGHT) do |y|
        if x == 0 || x == WIDTH-1 || y==0 || y == HEIGHT-1
          '-'
        else
          '?'
        end
      end
    end
    @memories = {}
    build
  end

  def calculate_los(x,y,r)
    @lit_spaces = []
    do_fov(x,y,r, WIDTH, HEIGHT)
  end
  def light(x,y)
    @lit_spaces << [x,y]
    @memories[[x,y]] = @map[x][y].dup
  end
  def lit?(x,y)
    @lit_spaces.include?([x,y])
  end
  def blocked?(x,y)
    @map[x][y].block_los?
  end
  def memory(x,y)
    @memories[[x,y]]
  end

  attr_reader :map

  def build
    starting_vault = Vault.start.shuffle.pop.variations.shuffle.pop
    place_vault!([10,10], starting_vault)
    placed_vaults = 0
    failures_in_this_sequence = 0
    while placed_vaults < 10 && failures_in_this_sequence < 1000

      # puts "looking at map:"
      # map.each do |row|
      #   puts row.join("")
      # end
      # puts

      current_starting_point = open_spaces.shuffle.pop
      # puts "now using this one:"
      # _x,_y = current_starting_point
      # map[_x][_y] = '^'
      # map.each do |row|
      #   puts row.join("")
      # end
      # map[_x][_y] = '?'
      # sleep 0.1

      raise "no valid starting space!" unless current_starting_point
      break unless current_starting_point
      new_vault = Vault.all.shuffle.pop
      placed_vault_this_iteration = false
      new_vault.variations.shuffle.take_while do |v|
        if can_place_vault?(current_starting_point, v)
          place_vault!(current_starting_point, v)
          placed_vault_this_iteration = true
          false
        else
          true
        end
      end

      if placed_vault_this_iteration
        placed_vaults += 1
        failures_in_this_sequence = 0
      else
        failures_in_this_sequence += 1
      end
    end
    # puts "placed #{placed_vaults} vaults"

    fill_in_empty_space
  end

  def fill_in_empty_space
    WIDTH.times do |x|
      HEIGHT.times do |y|
        @map[x][y] = '#' if map[x][y] == '?'
        # @map[x][y] = '.' if map[x][y] == '*'
        @map[x][y] = '.' if map[x][y] == '.'

        @map[x][y] = Tile.build(x, y, @map[x][y])
      end
    end
  end

  def find_terrain t
    WIDTH.times do |x|
      HEIGHT.times do |y|
        return map[x][y] if map[x][y].terrain == t
      end
    end
  end

  def off_map?(x,y)
    x < 0 || y < 0 || y >= HEIGHT || x >= WIDTH
  end

  def lazy_tiles
    ['?']
  end

  def can_place_vault?(position, vault)
    x,y = position
    # binding.pry
    x -= vault.ox
    y -= vault.oy
    # binding.pry
    vault.width.times do |w|
      vault.height.times do |h|
        next if (lazy_tiles + ['$']).include?(vault.map[w][h])
        return false if off_map?(x+w,y+h)
        return false unless lazy_tiles.include?(@map[x+w][y+h])
      end
    end
    return true
  end

  def place_vault!(position, vault)
    x,y = position
    x -= vault.ox
    y -= vault.oy
    vault.width.times do |w|
      vault.height.times do |h|
        next if lazy_tiles.include?(vault.map[w][h])
        if %w($).include?(vault.map[w][h])
          @map[x+w][y+h] = '.'
        else
          @map[x+w][y+h] = vault.map[w][h]
        end
      end
    end
  end

  def open_spaces
    rtn = []
    WIDTH.times do |x|
      HEIGHT.times do |y|
        if @map[x][y] == '?'
          [-1,0,1].each do |dx|
            [-1,0,1].each do |dy|
              if dx.abs + dy.abs == 1 &&
                !off_map?(x+dx,y+dy) &&
                @map[x+dx][y+dy] == '.'
                rtn << [x,y]
              end
            end
          end
        end
      end
    end
    return rtn.uniq
  end

  def at(x,y)
    @map[x][y]
  end
end

# l = Level.new
# l.map.each do |row|
#   puts row.join("")
# end
# exit

class Player
  def initialize(tile)
    @location = tile
    tile.monster = self
    @energy = 3
  end
  def move!(tile)
    if @location
      @location.monster = nil
    end
    tile.monster = self
    @location = tile
  end
  def x
    @location.x
  end
  def y
    @location.y
  end
  def chr
    '@'
  end
  attr_accessor :energy

  [1,2,3].each do |i|
    define_method("item#{i}") do
      nil
    end
  end
end

class MainGame
  def initialize
    @level = Level.new
    @player = Player.new(@level.find_terrain('<'))
  end
  def should_process_input?
    true
  end
  def should_idle?
    false
  end
  def draw
    draw_map(0,0)
    draw_status(WIDTH+1,0)
    Curses::refresh
  end
  def draw_map(offset_x, offset_y)
    @level.calculate_los(@player.x, @player.y, 5)
    WIDTH.times do |x|
      HEIGHT.times do |y|
        Curses::setpos(y+offset_y,x+offset_x)
        if @level.lit?(x,y)
          draw_str(@level.map[x][y].chr, :white)
        elsif @level.memory(x,y)
          draw_str(@level.memory(x,y).chr, :gray)
        else
          draw_str(" ", :white)
        end
      end
    end
  end
  def draw_status(offset_x, offset_y)
    [
      "Commando",
      "hp: 10/10",
      "",
      "*"*@player.energy,
      "",
      @player.item1,
      @player.item2,
      @player.item3,
    ].each_with_index do |(str, color),i|
      Curses::setpos(i+offset_y,offset_x)
      draw_str(str,color||:white)
    end
  end

  def draw_str(str, color)
    # binding.pry unless color
    Curses::attron(Curses::color_pair(c(color)) | (COLOR_ATTRS[color]||0) | Curses::A_NORMAL) do
      Curses::addstr(str||"")
    end
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
    end
    self
  end

  def attempt_move(tile)
    if tile.can_move_into?
      @player.move!(tile)
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
  Curses::init_pair(c(:white),Curses::COLOR_WHITE,Curses::COLOR_BLACK)
  # COLOR_ATTRS[:white] = Curses::A_BOLD
  Curses::init_pair(c(:blue),Curses::COLOR_BLUE,Curses::COLOR_BLACK)
  Curses::init_pair(c(:red),Curses::COLOR_RED,Curses::COLOR_BLACK)
  Curses::init_pair(c(:green),Curses::COLOR_GREEN,Curses::COLOR_BLACK)
  Curses::init_pair(c(:gray),Curses::COLOR_BLACK,Curses::COLOR_BLACK)
  COLOR_ATTRS[:gray] = Curses::A_BOLD

  current_action = m
  Curses::curs_set(0)

  loop do
    current_action.draw
    current_action = current_action.idle! if current_action.should_idle?
    current_action = current_action.process_input!(Curses::getch) if current_action.should_process_input?
  end
ensure
  Curses::close_screen
end
