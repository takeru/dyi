# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'dyi'

chart = DYI::Chart::PieChart.new 400,500,
  :data_label_format => "{?name}\n{?percent}",
  :data_label_font => {:size => 20, :font_family=>'Serif'},
  :represent_3d => true,
  :show_data_label => false,
  :show_baloon => true,
  :baloon_opacity => 0.3,
  :baloon_format => "{?name}\n{?percent}",
#  :moved_elements => [0.2,nil,nil,0.5],
#  :chart_colors => ['blue', 'red', 'yellow', 'green'],
  :_3d_settings => {:dy => 30},
  :background_image_file => {:path => 'data/background.png', :content_type=>'image/png'},
  :background_image_opacity => 0.1,
  :legend_format => "{?name}\t{!e}{?value:#,##0}\t{!e}({?percent:0.00%})",
  :chart_stroke_color => 'white'

reader = DYI::Chart::ExcelReader.read('data/currency.xlsx', :schema => [:name, :value])
chart.load_data reader

chart.save 'output/pie_chart.svg'
chart.save 'output/pie_chart.xaml', :xaml
chart.save 'output/pie_chart.eps', :eps
chart.save 'output/pie_chart.emf', :emf if defined? IRONRUBY_VERSION
