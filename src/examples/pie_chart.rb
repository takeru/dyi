# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'dyi'

chart = DYI::Chart::PieChart.new 400,500,
  :data_label_format => "{name}\n{percent}",
  :represent_3d => true,
  :moved_elements => [0.2,nil,nil,0.5],
  :chart_colors => ['blue', 'red', 'yellow', 'green'],
  :_3d_settings => {:dy => 30},
  :chart_stroke_color => 'white'

reader = DYI::Chart::ExcelReader.read('data/currency.xlsx', :title_column=>0, :column_skip=>1)
chart.load_data reader

chart.save 'output/pie_chart.svg'
chart.save 'output/pie_chart.xaml', :xaml
chart.save 'output/pie_chart.eps', :eps
chart.save 'output/pie_chart.emf', :emf if defined? IRONRUBY_VERSION
