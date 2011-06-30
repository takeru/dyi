# -*- encoding: UTF-8 -*-

require '../lib/dyi'

chart = DYI::Chart::PieChart.new 400,500,
  :data_label_format => "{name}\n{percent}",
  :represent_3d => true,
  :moved_elements => [0.2,nil,nil,0.5],
  :chart_colors => ['blue', 'red', 'yellow', 'green'],
  :_3d_settings => {:dy => 30},
  :chart_stroke_color => 'white'

reader = DYI::Chart::ExcelReader.read('data/currency.xlsx', :title_column=>0, :column_skip=>1)
chart.load_data reader

chart.save 'output/test.svg'
chart.save 'output/test.xaml', :xaml
chart.save 'output/test.eps', :eps
chart.save 'output/test.emf', :emf if defined? IRONRUBY_VERSION
