# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/services/input_parser'

RSpec.describe InputParser do
  let(:classifier) { instance_double(ProductClassifier) }
  subject(:parser) { described_class.new(classifier: classifier) }

  before do
    allow(classifier).to receive(:classify).and_return(:other)
  end

  describe '#parse' do
    it 'returns a Receipt' do
      expect(parser.parse('')).to be_a(Receipt)
    end

    it 'parses a single line into a line item' do
      allow(classifier).to receive(:classify).with('book').and_return(:book)

      receipt = parser.parse('1 book at 12.49')
      item = receipt.line_items.first

      expect(receipt.line_items.size).to eq(1)
      expect(item.quantity).to eq(1)
      expect(item.product.name).to eq('book')
      expect(item.product.base_price).to eq(12.49)
      expect(item.product.category).to eq(:book)
      expect(item.product.imported).to be false
    end

    it 'parses multiple lines, one line item per line' do
      allow(classifier).to receive(:classify).with('book').and_return(:book)
      allow(classifier).to receive(:classify).with('music CD').and_return(:other)

      receipt = parser.parse(<<~INPUT)
        1 book at 12.49
        1 music CD at 14.99
      INPUT

      expect(receipt.line_items.size).to eq(2)
      expect(receipt.line_items.map { |i| i.product.name }).to eq(['book', 'music CD'])
    end

    it 'marks a product as imported when the description contains "imported"' do
      receipt = parser.parse('1 imported box of chocolates at 10.00')

      expect(receipt.line_items.first.product.imported).to be true
    end

    it 'does not mark a product as imported when the description does not contain "imported"' do
      receipt = parser.parse('1 box of chocolates at 10.00')

      expect(receipt.line_items.first.product.imported).to be false
    end

    it 'is case-insensitive when detecting "imported"' do
      receipt = parser.parse('1 Imported perfume at 27.99')

      expect(receipt.line_items.first.product.imported).to be true
    end

    it 'uses the classifier to determine the product category' do
      allow(classifier).to receive(:classify).with('headache pills').and_return(:medical)

      receipt = parser.parse('1 headache pills at 9.75')

      expect(receipt.line_items.first.product.category).to eq(:medical)
      expect(classifier).to have_received(:classify).with('headache pills')
    end

    it 'parses quantities greater than one' do
      receipt = parser.parse('3 book at 12.49')

      expect(receipt.line_items.first.quantity).to eq(3)
    end

    it 'parses prices with no decimal part' do
      receipt = parser.parse('1 book at 12')

      expect(receipt.line_items.first.product.base_price).to eq(12.0)
    end

    it 'ignores blank lines' do
      receipt = parser.parse(<<~INPUT)
        1 book at 12.49

        1 music CD at 14.99
      INPUT

      expect(receipt.line_items.size).to eq(2)
    end

    it 'ignores lines that do not match the expected format' do
      receipt = parser.parse(<<~INPUT)
        1 book at 12.49
        this is not a valid line
      INPUT

      expect(receipt.line_items.size).to eq(1)
    end

    it 'skips a line with a zero quantity without aborting the rest of the receipt' do
      receipt = parser.parse(<<~INPUT)
        1 book at 12.49
        0 music CD at 14.99
      INPUT

      expect(receipt.line_items.size).to eq(1)
      expect(receipt.line_items.first.product.name).to eq('book')
    end

    it 'skips a line with a negative price, warning instead of staying silent' do
      expect do
        receipt = parser.parse(<<~INPUT)
          1 book at 12.49
          1 box of hot dogs at -987
        INPUT

        expect(receipt.line_items.size).to eq(1)
        expect(receipt.line_items.first.product.name).to eq('book')
      end.to output(/Skipping invalid line.*box of hot dogs.*-987/).to_stderr
    end

    it 'skips a line with a negative quantity, warning instead of staying silent' do
      expect do
        receipt = parser.parse(<<~INPUT)
          1 book at 12.49
          -1 music CD at 14.99
        INPUT

        expect(receipt.line_items.size).to eq(1)
        expect(receipt.line_items.first.product.name).to eq('book')
      end.to output(/Skipping invalid line.*music CD/).to_stderr
    end

    it 'strips surrounding whitespace from each line' do
      receipt = parser.parse("   1 book at 12.49   \n")

      expect(receipt.line_items.size).to eq(1)
      expect(receipt.line_items.first.product.name).to eq('book')
    end

    it 'returns an empty receipt for blank input' do
      receipt = parser.parse("\n\n")

      expect(receipt.line_items).to be_empty
    end

    it 'defaults to a real ProductClassifier when none is given' do
      expect(described_class.new.instance_variable_get(:@classifier)).to be_a(ProductClassifier)
    end
  end
end
