#!/usr/bin/env ruby

require 'open3'

# cmd = 'cat -u -n' # -u disables output buffering, -n numbers output lines (to distinguish from input)
# input_lines = ['line1', 'line2', 'line3', "\C-d"] # TODO: how to send Ctrl-D to exit without timeout?

cmd = 'irb -f --prompt=default'
input_lines = ['puts "hi"', 'puts "aaa\nbbb\nccc"', 'puts "bye"', 'exit']

# cmd = 'nslookup localhost'
# input_lines = []

def puts_input_line_to_stdin(stdin, input_lines)
  input_line = input_lines.shift
  unless input_line
    # puts 'No more input lines to read'
    return
  end
  # puts "About to puts input line '#{input_line}' to stdin #{stdin}"
  stdin.puts(input_line)
end

def readline_nonblock(io)
  # puts 'in readline_nonblock...'
  buffer = ""
  while ch = io.read_nonblock(1)
    buffer << ch
    if ch == "\n" then
      result = buffer
      # puts "returning result line from read_nonblock: #{result}"
      return result
    end
  end
end

# puts "Calling Open3.popen2e for cmd '#{cmd}'"
rc = nil
output_timeout = 2.0
n = 0
Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
  output = ''
  line = nil
  begin
    n += 1
    # puts "about to gets from output for #{n} time"
    while line = readline_nonblock(stdout_and_stderr)
      # puts "in begin loop, line is '#{line}'"
      output += line
      # puts "Appended line '#{line}' to output"
      line = nil
    end
  rescue EOFError => e
    # puts "Got EOFError = #{e.inspect}"
    unless input_lines.empty?
      raise "Output Stream closed with input lines left unprocessed! - #{input_lines.inspect}"
    end
  rescue IO::WaitWritable => e
    # Can never happen if you only use read_writeable?
    raise "Got WaitWritable = #{e.inspect}"
  rescue IO::WaitReadable
    # puts "Rescued IO::WaitReadable"
    if input_lines.empty?
      # puts "No input lines"
      # puts "about to io.select with NO input pending, stdout_and_stderr = #{stdout_and_stderr.inspect}"
      result = IO.select([stdout_and_stderr], nil, nil, output_timeout)
      # puts "io select result = #{result}"
      retry unless result.nil?
    else
      puts_input_line_to_stdin(stdin, input_lines)
      # puts "about to io.select with input pending, stdout_and_stderr = #{stdout_and_stderr.inspect}"
      result = IO.select([stdout_and_stderr], nil, nil)
      retry
    end
  end
  # puts 'left begin loop'
  # puts 'closing stdin IO'
  stdin.close

  rc = wait_thr.value.exitstatus
  puts 'output:'
  puts output
end
puts "rc=#{rc}"
