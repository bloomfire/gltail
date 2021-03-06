# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Block
  include GlTail::Configurable

  attr_reader :name, :bottom_position

  config_attribute :color, "FIXME: add description", :type => :color
  config_attribute :order, "FIXME"
  config_attribute :size, "FIXME"
  config_attribute :auto_clean, "FIXME"
  config_attribute :activity_type, "FIXME"

  attr_accessor :column
  attr_reader   :config
  attr_reader   :max_rate

  def initialize(config, name)
    @config = config
    @name = name

    @size = 10
    @auto_clean = true
    @activity_type = "blobs"
    @order = 100

    @show = 0

    @header = Element.new(self, @name.upcase, [1.0, 1.0, 1.0, 1.0])

    @elements = { }
    @bottom_position = -@config.screen.top
    @max_rate = 1.0/599
    @last_clean = 0

    @sorted = []
  end

  def show=(value)
    @show = case value
    when 'rate' then 0
    when 'total' then 1
    when 'average' then 2
    when 'instant' then 4
    when 'instantd' then 5
    else
      0
    end
  end

  attr_reader :show

  def top
    @config.screen.top
  end

  def line_size
    @config.screen.line_size
  end

  def is_right
    column.is_right
  end

  def alignment
    column.alignment
  end

  def position
    column.position
  end

  def width
    column.size
  end

  def render(engine, num)
    return num if @elements.size == 0 || @sorted.size == 0

    @header.wy = top - (num * line_size)
    @header.render(engine)
    num += 1

    count = 0

    for e in @sorted[0..@size] do
      engine.stats[0] += 1
      e.wy = top - (num * line_size)
      e.render(engine)
      num += 1
      @max_rate = e.rate if e.rate > @max_rate
    end

    @bottom_position = top - ((@sorted.size > 0 ? (num-1) : num) * line_size)
    num + 1
  end

  def add_activity(options = { })
    return unless options[:name]
    x = nil
    unless @elements[options[:name]]
      x = Element.new(self, options[:name], @color || options[:color] )
      @elements[options[:name]] = x
      if @sorted.size > @size
        @sorted.insert(@size+1,x)
      else
        @sorted << x
      end
    else
      x = @elements[options[:name]]
    end
    x.add_activity(options[:message], @color || options[:color], options[:size] || 0.01, options[:type] || 0, options[:real_size] || options[:size] )
  end

  def add_event(options = { })
    return unless options[:name]
    x = nil
    unless @elements[options[:name]]
      x = Element.new(self, options[:name], @color || options[:color] )
      @elements[options[:name]] = x
      if @sorted.size > @size
        @sorted.insert(@size+1,x)
      else
        @sorted << x
      end
    else
      x = @elements[options[:name]]
    end

    x.add_event(options[:message], options[:color] || @color, options[:update_stats] || false)
  end

  def update
    deleted = []
    @last_clean = 0 if @last_clean > @sorted.size
    
    if @last_clean < @sorted.size
      #		puts "Cleaning #{@last_clean} => #{@last_clean + 10} (#{@sorted.size})" if @name == "urls"
      @sorted[@last_clean..(@last_clean + 10)].each do |e|
        #        e.render_events(engine)
        if e.activities.size == 0 && e.rate <= 0.001 && @auto_clean
          deleted << e
        end
      end
    else
      @last_clean = 0
    end 
    
    @last_clean += 10

    for e in deleted do 
      @elements.delete(e.name)
      @sorted.delete(e)
      e.free_vertex_lists
    end

    return if @sorted.size == 0

    @max_rate = @max_rate * 0.9999
    i = 1
    @sorted[0].update
    @ordered = [@sorted[0]]
    min_pos = 0
    size = @sorted.size

    if @show == 0
      min = @sorted[0].rate
      while i < size
        @sorted[i].update
        rate = @sorted[i].rate
        if rate > min
          j = min_pos
          while @ordered[j-1].rate < rate && j > 0
            j -= 1
          end
          @ordered.insert(j, @sorted[i])
        else
          @ordered << @sorted[i]
          if i < @size
            min = rate
          end
        end
        min_pos = i
        i += 1
      end
    elsif @show == 1
      min = @sorted[0].total
      while i < size
        @sorted[i].update
        total = @sorted[i].total
        if total > min
          j = min_pos
          while @ordered[j-1].total < total && j > 0
            j -= 1
          end
          @ordered.insert(j, @sorted[i])
        else
          @ordered << @sorted[i]
          if i < @size
            min = total
          end
        end
        min_pos = i
        i += 1
      end
    elsif @show == 2
      min = @sorted[0].average
      while i < size
        @sorted[i].update
        average = @sorted[i].average
        if average > min
          j = min_pos
          while @ordered[j-1].average < average && j > 0
            j -= 1
          end
          @ordered.insert(j, @sorted[i])
        else
          @ordered << @sorted[i]
          if i < @size
            min = average
          end
        end
        min_pos = i
        i += 1
      end

    elsif @show == 4 || @show == 5
      min = @sorted[0].instant
      while i < size
        @sorted[i].update
        instant = @sorted[i].instant
        if instant > min
          j = min_pos
          while @ordered[j-1].instant < instant && j > 0
            j -= 1
          end
          @ordered.insert(j, @sorted[i])
        else
          @ordered << @sorted[i]
          if i < @size
            min = instant
          end
        end
        min_pos = i
        i += 1
      end
    end

    @sorted = @ordered
  end

  def reshape
    @header.reshape
    @sorted.each do |e|
      e.reshape
    end 
  end 

end
