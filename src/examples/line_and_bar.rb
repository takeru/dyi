# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'dyi'

chart = DYI::Chart::LineChart.new 800,500,
  :use_y_second_axises => [true, nil],
  :chart_margins => {:left => 80, :right => 70, :bottom => 50},
  :axis_format => '#,##0',
  :axis_settings => {:min => 4000000},
  :max_x_label_count => 20,
  :data_columns => [0, 1],
  :chart_types => [:line, :bar],
  :line_width => 3,
  :show_dropshadow => true,
#  :represent_3d => true,
#  :_3d_settings => {:dx => 30, :dy => -10},
  :show_legend => false,
  :legend_point => [50, 480]

reader = DYI::Chart::CsvReader.read('data/money.csv', :data_types => [:string, :number, :number, :string], :schema => [:name, :value, :value, :color])
chart.load_data reader

chart.save 'output/line_and_bar.svg'
chart.save 'output/line_and_bar.eps', :eps
chart.save 'output/line_and_bar.emf', :emf if defined? IRONRUBY_VERSION
