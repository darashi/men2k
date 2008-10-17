#!/usr/bin/env ruby
# men2k.rb
# SHIDARA Yohji
# http://d.hatena.ne.jp/darashi

begin
  require "poppler"
rescue RuntimeError
  raise unless $!.message =~ /^Cannot open display:/
  retry
end

class Numeric
  # mmをptに変換して返す
  def mm
    self/0.352778
  end
end

class Men2K
  def initialize(output)
    paper_a4
    card_2_5
    @surface = Cairo::PDFSurface.new(output, @width, @height)
    @rotate_even_rows = true
    @rotate_even_columns = false
    @i = 0
    @need_show_page = true
    @context = Cairo::Context.new(@surface)
  end
  # ページあたりのカード数
  def cards_in_a_page
    @rows * @columns
  end
  def draw_page(input, n=cards_in_a_page)
    @card = Poppler::Document.new(input)
    page = @card[0]
    n.times do
      row, column = @i.divmod(@columns)
      row %= @rows
      x = @margin_left + (@card_width+@horizontal_margin) * column
      y = @margin_top + (@card_height+@vertical_margin) * row
      @context.save do
        @context.translate(x, y)
        if (@rotate_even_rows && row % 2 == 1) ||
           (@rotate_even_columns && column % 2 == 1 )
          @context.rotate(Math::PI)
          @context.translate(-@card_width, -@card_height)
        end
        @context.render_poppler_page(page)
      end
      @i += 1
      @need_show_page = (@i % cards_in_a_page).zero?
      show_page if @need_show_page
    end
  end
  def finish
    show_page unless @need_show_page # 途中で終わった場合
    @surface.finish
  end
  private
  def paper_a4
    @width, @height = 210.mm, 297.mm
  end
  def card_2_5
    @columns, @rows = 2, 5
    @card_width, @card_height = 91.mm, 55.mm
    @margin_left, @margin_top = 14.mm, 11.mm
    @vertical_margin = @horizontal_margin = 0
  end
  def card_2_4
    # A-one F8A4-1
    @columns, @rows = 2, 4
    @card_width, @card_height = 91.mm, 55.mm
    @margin_left, @margin_top = 15.mm, 25.mm
    @horizontal_margin = 8.mm
    @vertical_margin = 9.mm
  end
  def show_page
    trim_mark
    @context.show_page
  end
  def trim_mark
    x = @margin_left
    y = @margin_top
    h = @card_height*@rows + @vertical_margin*(@rows-1) # 印刷領域高さ
    w = @card_width*@columns + @horizontal_margin*(@columns-1) # 印刷領域幅
    d = 3.mm
    l = 36
    @context.set_line_width(0.3)
    def corner(x,y,d,l,alpha,beta)
      @context.move_to(x+alpha*(d+l),y)
      @context.line_to(x+alpha*d,y)
      @context.line_to(x+alpha*d,y+beta*(d+l))
      @context.stroke
      @context.move_to(x+alpha*(d+l),y+beta*d)
      @context.line_to(x,y+beta*d)
      @context.line_to(x,y+beta*(d+l))
      @context.stroke
    end
    def center(x,y,d,l,alpha,beta)
      if beta > 0
        @context.move_to(x,y+alpha*(d+l))
        @context.line_to(x,y+alpha*d)
        @context.stroke
        @context.move_to(x-l,y+alpha*2*d)
        @context.line_to(x+l,y+alpha*2*d)
        @context.stroke
      else
        @context.move_to(x+alpha*(d+l),y)
        @context.line_to(x+alpha*d,y)
        @context.stroke
        @context.move_to(x+alpha*2*d,y-l)
        @context.line_to(x+alpha*2*d,y+l)
        @context.stroke
      end
    end
    corner(x  ,y  ,d,l,-1,-1)
    corner(x  ,y+h,d,l,-1,+1)
    corner(x+w,y  ,d,l,+1,-1)
    corner(x+w,y+h,d,l,+1,+1)
    if @center_mark
      center(x  ,y+h/2.0,d,l,-1,-1)
      center(x+w,y+h/2.0,d,l,+1,-1)
      center(x+w/2.0,y  ,d,l,-1,+1)
      center(x+w/2.0,y+h,d,l,+1,+1)
    end

    # 水平方向の分割線
    for r in 1...@rows
      yy = y + @card_height*r + @vertical_margin*(r-1)
      # 鉛直線
      @context.stroke do
        @context.move_to(x+w+2*d,yy-l)
        @context.line_to(x+w+2*d,yy+@vertical_margin+l)
      end
      @context.stroke do
        @context.move_to(x-2*d,yy-l)
        @context.line_to(x-2*d,yy+@vertical_margin+l)
      end
      # 水平線
      @context.stroke do
        @context.move_to(x-d-l,yy)
        @context.line_to(x-d,yy)
      end
      @context.stroke do
        @context.move_to(x+w+d,yy)
        @context.line_to(x+w+d+l,yy)
      end
      if @vertical_margin > 0
        @context.stroke do
          @context.move_to(x-d-l,yy+@vertical_margin)
          @context.line_to(x-d,yy+@vertical_margin)
        end
        @context.stroke do
          @context.move_to(x+w+d,yy+@vertical_margin)
          @context.line_to(x+w+d+l,yy+@vertical_margin)
        end
      end
    end

    # 鉛直方向の分割線
    for c in 1...@columns
      xx = x + @card_width*c+@horizontal_margin*(c-1)
      # 水平線(補助線)
      @context.stroke do
        @context.move_to(xx-l,y-2*d)
        @context.line_to(xx+@horizontal_margin+l, y-2*d)
      end
      @context.stroke do
        @context.move_to(xx-l,y+h+2*d)
        @context.line_to(xx+@horizontal_margin+l, y+h+2*d)
      end
      # 鉛直線(分割線)
      @context.stroke do
        @context.move_to(xx,y-d-l)
        @context.line_to(xx,y-d)
      end
      @context.stroke do
        @context.move_to(xx,y+h+d+l)
        @context.line_to(xx,y+h+d)
      end
      if @horizontal_margin > 0
        @context.stroke do
          @context.move_to(xx+@horizontal_margin,y-d-l)
          @context.line_to(xx+@horizontal_margin,y-d)
        end
        @context.stroke do
          @context.move_to(xx+@horizontal_margin,y+h+d+l)
          @context.line_to(xx+@horizontal_margin,y+h+d)
        end
      end
    end
  end
end

if ARGV.size < 1
  puts "usage: #{$0} [input1.pdf] [input2.pdf] ..."
  exit(-1)
end

output = "out-%d.pdf" % Time.now
puts "writing %s" % output

m2k = Men2K.new(output)
ARGV.each do |input|
  m2k.draw_page(input)
end
m2k.finish
