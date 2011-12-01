def compress_ecmacript(script, start_variable='a')
  str_reg = /("[^"]*[^\\\\]"|'[^']*[^\\\\]'|""|''|#\{[^\}]*\})/
  strings = []
  script.gsub!(str_reg) do
    strings << $&
    "``s#{strings.size - 1}``"
  end

  var_reg1 = /\bvar\s+([$A-Z_a-z][$A-Z_a-z0-9]*).*?(;|\z|[^\s,][\t\v ]*\n)/m
  var_reg2 = /,\s*([$A-Z_a-z][$A-Z_a-z0-9]*)/m
  target = script
  variables, new_variables = [], []

  while target =~ var_reg1
    variables << $1 unless variables.include?($1)
    target = $'
    while $2 =~ var_reg2
      variables << $1 unless variables.include?($1)
    end
  end
  current_variable = start_variable
  variables.each_with_index do |name, i|
    new_variables << current_variable
    current_variable = current_variable.next
    script.gsub!(/\b#{name}\b/) do
      $`[-1,1] == "." ? $& : "``v#{i}``"
    end
  end

  script.gsub!(/``([sv])(\d+)``/) do
    case $1
      when 's' then strings[$2.to_i]
      when 'v' then new_variables[$2.to_i]
    end
  end

  script.gsub!(/\s+/) do
    pre = $`[-1,1]
    suf = $'[0,1]
    (pre =~ /\w/ && suf =~ /\w/) ? " " : ""
  end
  script
end
