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
    @radiation = 0
    @max_radiation = 1000
    build
  end

  def calculate_los(x,y,r)
    @lit_spaces = []
    do_fov(x,y,r, WIDTH, HEIGHT)
  end
  def light(x,y)
    @lit_spaces << [x,y]
    @memories[[x,y]] = @map[x][y].chr
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

  def process_radiation!
    @radiation += 1
    if @radiation >= @max_radiation
      @player.get_hit(1)
    end
  end

  def radiation_pct
    (@radiation*100)/@max_radiation
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
