class Level
  include PermissiveFieldOfView
  attr_reader :difficulty
  MAX_DIFFICULTY = 16
  def initialize(difficulty)
    @difficulty = difficulty
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
    @max_radiation = 300 + (200*difficulty)/MAX_DIFFICULTY
    build
  end

  def calculate_los(c,r=99)
    @save_memories = c.is_a?(Player)
    @lit_spaces = []
    do_fov(c.x,c.y,r, WIDTH, HEIGHT)
  end
  def light(x,y)
    @lit_spaces << [x,y]
    @memories[[x,y]] = @map[x][y].chr if @save_memories
  end
  def scry_terrain(x,y)
    unless memory(x,y)
      @memories[[x,y]] = @map[x][y].terrain
    end
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

  def process_radiation!(player)
    @radiation += 1
    if @radiation >= @max_radiation
      player.get_hit(1, player)
    end
  end

  def radiation_pct
    (@radiation*100)/@max_radiation
  end

  SCENT_DECAY_PER_TILE = 1.0
  EMITTED_SCENT_PER_TURN = 50.0
  RETAINED_SCENT = 10.0
  MAX_SCENT = 100
  ITERATIONS = 1

  def process_scent!(player)
    ITERATIONS.times do
      new_scent_values = Hash.new(0.0)
      player.location.scent += EMITTED_SCENT_PER_TURN
      WIDTH.times do |x|
        HEIGHT.times do |y|
          unless at(x,y).block_scent? || at(x,y).scent == 0
            scent_destinations = [at(x,y)]*RETAINED_SCENT
            [-1,0,1].each do |dx|
              [-1,0,1].each do |dy|
                unless off_map?(x+dx,y+dy)
                  t = at(x+dx,y+dy)
                  scent_destinations << t unless t.block_scent?
                end
              end
            end
            scent_destinations.each do |t|
              # now, scent_destinations contains all adjacent open tiles.
              new_scent_values[t] += at(x,y).scent/scent_destinations.count

              # alternatively, always imagine they spread to adjacent tiles, even if they're not expecting
              # new_scent_values[t] += at(x,y).scent/9
            end
          end
        end
      end
      new_scent_values.each do |t, s|
        t.scent = s-SCENT_DECAY_PER_TILE
        t.scent = 0 if t.scent < 0
        t.scent = MAX_SCENT if t.scent > MAX_SCENT
      end
    end
  end

  attr_reader :map

  VAULT_COUNT_GOAL = 30
  VAULT_COUNT_MINIMUM = 25

  def start_x
    @sx||=rand(WIDTH-10)+5
  end
  def start_y
    @sy||=rand(HEIGHT-10)+5
  end

  def build
    starting_vault = Vault.start.shuffle.pop.variations.shuffle.pop
    place_vault!([start_x,start_y], starting_vault)
    placed_vaults = 0
    failures_in_this_sequence = 0
    while placed_vaults < VAULT_COUNT_GOAL && failures_in_this_sequence < 1000

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
    raise "building failed" if placed_vaults < VAULT_COUNT_MINIMUM
    add_exit
    fill_in_empty_space!
    clear_out_awkward_diagonals!
    place_monsters_and_treasure
    build_tiles!
  end

  def add_exit
    ex,ey = open_spaces.shuffle.map do |s|
      [s, (start_x-s.first).abs + (start_y-s.last).abs]
    end.select{|(_a,_b),c| c > 15}.sort_by(&:last).last(30).shuffle.pop.first
    @map[ex][ey] = '>'
  end

  def place_monsters_and_treasure
    treasure = (['E']*(3 + rand(3))) + (['~']*rand(3))

    tiles = []
    WIDTH.times do |x|
      HEIGHT.times do |y|
        tiles << [x,y] if @map[x][y] == '.' && (start_x-x).abs + (start_y-y).abs > 10
      end
    end

    pending_monster_levels = (7 + 2*difficulty)

    while pending_monster_levels > 0
      tiles.shuffle!
      a,b = tiles.pop
      raise 'derp' unless a && b
      possibilities = case
      when difficulty > 14
        ['x','c','v']
      when difficulty > 11
        ['x','c','c','v']
      when difficulty > 8
        ['x','x','c','v']
      when difficulty > 5
        ['x','c']
      when difficulty > 2
        ['x','x','x','c']
      else
        ['x']
      end
      monster_glyph = 'x'
      case monster_glyph
      when 'x'
        pending_monster_levels -= 1
      end
      @map[a][b] = possibilities.shuffle.pop

    end
    treasure.each do |t|
      a,b = tiles.pop
      @map[a][b] = t
    end
  end

  def fill_in_empty_space!
    WIDTH.times do |x|
      HEIGHT.times do |y|
        @map[x][y] = '#' if map[x][y] == '?'
      end
    end
  end

  def clear_out_awkward_diagonals!
    count = nil
    until count == 0
      count = 0
      (WIDTH-1).times do |x|
        (HEIGHT-1).times do |y|
          if @map[x][y] == '#' &&
            @map[x+1][y+1] == '#' &&
            @map[x+1][y] == '.' &&
            @map[x][y+1] == '.'
            if rand(2)==0
              @map[x][y] = '.'
            else
              @map[x+1][y+1] = '.'
            end
            count += 1
          elsif
            @map[x][y] == '.' &&
            @map[x+1][y+1] == '.' &&
            @map[x+1][y] == '#' &&
            @map[x][y+1] == '#'
            if rand(2)==0
              @map[x+1][y] = '.'
            else
              @map[x][y+1] = '.'
            end
            count += 1
          end
        end
      end
    end
  end

  def build_tiles!
    WIDTH.times do |x|
      HEIGHT.times do |y|
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
        return false unless lazy_tiles.include?(@map[x+w][y+h]) || @map[x+w][y+h] == vault.map[w][h]
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
