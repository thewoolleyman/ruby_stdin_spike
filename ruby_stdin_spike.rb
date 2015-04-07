#!/usr/bin/env ruby

require 'open3'

cmd = 'cat -u -n' # -u disables output buffering, -n numbers output lines (to distinguish from input)
input_lines = ['line1','line2']

def puts_input_line_to_stdin(stdin, input_lines)
  input_line = input_lines.shift
  unless input_line
    puts 'No more input lines to read'
    return
  end
  puts "About to puts input line '#{input_line}' to stdin #{stdin}"
  stdin.puts(input_line)
end

puts "Calling Open3.popen2e for cmd '#{cmd}'"
Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
  output = ''
  puts_input_line_to_stdin(stdin, input_lines)
  puts 'about to gets from output for first time'
  line = stdout_and_stderr.gets
  puts "Starting while loop, first line is '#{line}'"
  while (line)
    output += line
    puts "Appended line '#{line}' to output"
    puts_input_line_to_stdin(stdin, input_lines)
    puts 'About to read another line from stdout_and_stderr.gets in the loop'
    line = stdout_and_stderr.gets
    puts "End of loop, read line '#{line}'"
  end

  puts output
end
