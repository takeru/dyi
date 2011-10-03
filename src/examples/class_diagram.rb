# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'dyi'

class ClassBox
  def initialize class_name
    @name = class_name
    @width = @name.length * 12
    @height = 30
    @children = []
  end
  
  def draw(canvas, pen, top_left_point, horizontal_span = 5)
    @top_left_point_x = top_left_point[0]
    @top_left_point_y = top_left_point[1]
    pen.draw_rectangle(canvas, top_left_point, @width, @height)
    pen.draw_text(canvas, [@top_left_point_x+@name.length * 2.5, @top_left_point_y+@height*3.0/4.0], @name)
    
    total_width = 0
    @children.each do |child|
      total_width += child.width + horizontal_span
    end
    total_width -= horizontal_span
    
    position_x = @top_left_point_x + @width/2.0 - total_width/2.0
    @children.each_with_index do |child, i|
      child.draw(canvas, pen, [position_x, @top_left_point_y+@height+30])
      pen.draw_arrow(canvas, child.get_top_center, [get_arrowhead_pos_x(i), @top_left_point_y+@height])
      position_x += child.width + horizontal_span
    end
    self
  end
  
  def extends parent
    parent.pushChildren self
    self
  end
  
  def pushChildren child
    @children.push child
  end
  
  def width
    @width
  end
  
  def get_top_center
    [@top_left_point_x + @width/2.0, @top_left_point_y]
  end
  
  def get_bottom_center
    [@top_left_point_x + @width/2.0, @top_left_point_y + @height]
  end
  
  private
  
  def get_arrowhead_pos_x index
    @top_left_point_x+(index+1)*@width/(@children.length+1)
  end
end

class ArrowPen < DYI::Drawing::Pen
  def draw_arrow(canvas, start_point, end_point, headsize = 5)
    start_point = DYI::Coordinate.new(start_point)
    end_point = DYI::Coordinate.new(end_point)
    total_length = DYI::Length.new(start_point.distance(end_point))
    end_point_no_rotate = DYI::Coordinate.new(start_point.x + total_length, start_point.y)
    
    rotate_value = Math.atan2((end_point.y - start_point.y).to_f, (end_point.x - start_point.x).to_f) * 360.0 / (2*Math::PI)
    
    draw_line(canvas, start_point, end_point_no_rotate).rotate(rotate_value, start_point)
    draw_polygon(canvas, end_point_no_rotate){|line|
      line.line_to([-headsize, -headsize], true)
      line.line_to([0, 2*headsize], true)
      line.line_to([headsize, -headsize], true)
    }.rotate(rotate_value, start_point)
  end
end

canvas = DYI::Canvas.new 1300, 1300

pen = ArrowPen.new
dashed_pen = ArrowPen.new(:stroke_dasharray => [3])

base_class = ClassBox.new('Base')
ClassBox.new('Table').extends(base_class)
ClassBox.new('PieChart').extends(base_class)
ClassBox.new('LineChart').extends(base_class)

pen.draw_rectangle(canvas, [30,10], 530, 260)
pen.draw_text(canvas, [60, 30], 'DYI::Chart')
base_class.draw(canvas, pen, [200,30])
legend = ClassBox.new('Legend').draw(canvas, pen, [350,30])
axis_util = ClassBox.new('AxisUtil').draw(canvas, pen, [450,30])
dashed_pen.draw_arrow(canvas, [200,90], legend.get_bottom_center)
dashed_pen.draw_arrow(canvas, [310,90], axis_util.get_bottom_center)

array_reader = ClassBox.new('ArrayReader')
ClassBox.new('CsvReader').extends(array_reader)
ClassBox.new('ExcelReader').extends(array_reader)

array_reader.draw(canvas, pen, [200, 170])

base_class = ClassBox.new('Base')
ClassBox.new('EpsFormatter').extends(base_class)
xml_formatter = ClassBox.new('XmlFormatter').extends(base_class)
ClassBox.new('EmfFormatter').extends(base_class)
ClassBox.new('SvgFormatter').extends(xml_formatter)
ClassBox.new('XamlFormatter').extends(xml_formatter)

pen.draw_rectangle(canvas, [30, 300], 480, 230)
pen.draw_text(canvas, [230, 320], 'DYI::Formatter')
base_class.draw(canvas, pen, [250,330])

pen_base_class = ClassBox.new('PenBase')
brush = ClassBox.new('Brush').extends(pen_base_class)
pen_class = ClassBox.new('Pen').extends(pen_base_class)
ClassBox.new('CylinderBrush').extends(brush)
ClassBox.new('CubicPen').extends(pen_class)

pen.draw_rectangle(canvas, [540, 300], 400, 230)
pen.draw_text(canvas, [730, 320], 'DYI::Drawing')
pen_base_class.draw(canvas, pen, [650,330], 90)
ClassBox.new('Canvas').draw(canvas, pen, [800,350])

comparable_class = ClassBox.new('Comparable').draw(canvas, pen, [50, 550])

pen.draw_rectangle(canvas, [30, 620], 270, 180)
pen.draw_text(canvas, [130, 640], 'DYI')
ClassBox.new('Length').draw(canvas, pen, [50, 650])
ClassBox.new('Coordinate').draw(canvas, pen, [150, 650])
ClassBox.new('Color').draw(canvas, pen, [50, 700])
ClassBox.new('Font').draw(canvas, pen, [200, 700])
ClassBox.new('Painting').draw(canvas, pen, [80, 750])
pen.draw_arrow(canvas, [122, 665], [150, 665])
dashed_pen.draw_arrow(canvas, [110, 650], comparable_class.get_bottom_center)

base_class = ClassBox.new('Base')
ClassBox.new('Rectangle').extends(base_class)
ClassBox.new('Circle').extends(base_class)
ClassBox.new('Ellipse').extends(base_class)
ClassBox.new('Line').extends(base_class)
polyline = ClassBox.new('Polyline').extends(base_class)
ClassBox.new('Path').extends(base_class)
ClassBox.new('Text').extends(base_class)
ClassBox.new('ShapeGroup').extends(base_class)
ClassBox.new('Polygon').extends(polyline)

pen.draw_rectangle(canvas, [310, 600], 770, 200)
pen.draw_text(canvas, [730, 620], 'DYI::Shape')
base_class.draw(canvas, pen, [650,630])

canvas.save 'output/class_diagram.svg'
