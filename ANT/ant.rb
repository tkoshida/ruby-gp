class Ant
  attr_reader :energy
  def initialize(world, energy)
    @energy = energy
    @x, @y = 0, 0
    @direction = 0 #   1
                   # 2 * 0
                   #   3
    @world = world
  end

  def move_forward
    unless @energy == 0
      case @direction
      when 0; move_right
      when 1; move_up
      when 2; move_left
      when 3; move_down
      end
      @energy -= 1
      return 1 if @world.proceed(@x, @y)
    end
    return 0
  end

  def turn_left
    unless @energy == 0
      @direction = (@direction + 3) % 4
      @energy -= 1
    end
    return 0
  end

  def turn_right
    unless @energy == 0
      @direction = (@direction + 1) % 4
      @energy -= 1
    end
    return 0
  end

  def is_food_ahead?
    ret = case @direction
           when 0; @world.is_food_at?(@x + 1, @y    ) # right
           when 1; @world.is_food_at?(@x,     @y + 1) # up
           when 2; @world.is_food_at?(@x - 1, @y    ) # left
           when 3; @world.is_food_at?(@x,     @y - 1) # down
           end
    return 1 if ret == true
    return 0
  end

  def show_world
    @world.show
  end

  def score
    @world.score
  end

  #######
  private
  #######

  def move_up
    @y -= 1 if @y > 0
  end

  def move_down
    @y += 1 if @y < @world.vertical - 1
  end

  def move_left
    @x -= 1 if @x > 0
  end

  def move_right
    @x += 1 if @x < @world.horizontal - 1
  end
end
