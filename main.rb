#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/services/input_parser'

# Interactive CLI loop: prints instructions, collects basket lines, prints
# the receipt on checkout, then lets the user start a new basket or exit.
class SalesTaxApplication
  CHECKOUT_COMMAND = 'checkout'
  EXIT_COMMAND = 'exit'
  NEW_COMMAND = 'new'

  def initialize(parser: InputParser.new, input: $stdin, output: $stdout)
    @parser = parser
    @input = input
    @output = output
  end

  def run
    print_header

    loop do
      lines = read_basket
      break if lines.nil?

      print_receipt(lines)
      break unless continue?
    end
  end

  private

  def print_header
    @output.puts '=== Sales Tax Calculator ==='
    @output.puts 'Enter one item per line as: <quantity> <description> at <price>'
    @output.puts 'Example: 2 book at 12.49'
    @output.puts
    @output.puts "Type '#{CHECKOUT_COMMAND}' when you're done adding items to see the receipt."
    @output.puts "Type '#{EXIT_COMMAND}' to quit without calculating."
    @output.puts
  end

  def read_basket
    lines = []

    while (line = @input.gets)
      command = line.strip.downcase
      return lines if command == CHECKOUT_COMMAND
      return nil if command == EXIT_COMMAND

      lines << line
    end

    lines
  end

  def print_receipt(lines)
    @output.puts
    @output.puts @parser.parse(lines.join("\n")).to_s
    @output.puts
  end

  # @return [Boolean] true to start a new basket, false to exit
  def continue?
    @output.puts "Type '#{NEW_COMMAND}' to start a new basket, or '#{EXIT_COMMAND}' to quit."

    while (line = @input.gets)
      command = line.strip.downcase
      return false if command == EXIT_COMMAND
      next unless command == NEW_COMMAND

      print_header
      return true
    end

    false
  end
end

SalesTaxApplication.new.run if __FILE__ == $PROGRAM_NAME
