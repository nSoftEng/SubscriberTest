# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/models/receipt'
require_relative '../../lib/models/line_item'

RSpec.describe Receipt do
  subject(:receipt) { described_class.new }

  let(:book)          { build(:domestic_book, base_price: 12.49) }
  let(:music_cd)      { build(:product, category: :other, description: 'music CD', base_price: 14.99) }
  let(:chocolate_bar) { build(:domestic_food, description: 'chocolate bar', base_price: 0.85) }

  let(:book_item)       { LineItem.new(quantity: 2, product: book) }
  let(:music_cd_item)   { LineItem.new(quantity: 1, product: music_cd) }
  let(:chocolate_item)  { LineItem.new(quantity: 1, product: chocolate_bar) }

  def line_item(quantity:, description:, category:, imported: false, base_price:)
    product = build(:product, description: description, category: category, imported: imported, base_price: base_price)
    LineItem.new(quantity: quantity, product: product)
  end

  describe '#initialize' do
    it 'starts with no line items' do
      expect(receipt.line_items).to eq([])
    end
  end

  describe '#add_item' do
    it 'adds the line item to line_items' do
      receipt.add_item(book_item)

      expect(receipt.line_items).to eq([book_item])
    end

    it 'preserves the order items were added in' do
      receipt.add_item(book_item).add_item(music_cd_item)

      expect(receipt.line_items).to eq([book_item, music_cd_item])
    end

    it 'returns self so calls can be chained' do
      expect(receipt.add_item(book_item)).to eq(receipt)
    end

    it 'allows the same line item to be added more than once' do
      receipt.add_item(book_item).add_item(book_item)

      expect(receipt.line_items).to eq([book_item, book_item])
    end
  end

  describe '#total_tax' do
    it 'returns 0 when there are no line items' do
      expect(receipt.total_tax).to eq(0)
    end

    it 'returns the tax amount of a single line item' do
      # music CD is not tax-exempt: 14.99 * 0.10 = 1.499, rounded up to 1.50
      receipt.add_item(music_cd_item)

      expect(receipt.total_tax).to eq(1.50)
    end

    it 'sums each applicable tax rule independently for an imported, non-exempt item' do
      # imported bottle of perfume (not tax-exempt):
      # basic: 47.50 * 0.10 = 4.75 (already a multiple of 0.05)
      # import: 47.50 * 0.05 = 2.375, rounded up to 2.40
      # total: 4.75 + 2.40 = 7.15
      perfume_item = line_item(quantity: 1, 
                                description: 'imported bottle of perfume', 
                                category: :other, 
                                imported: true,
                                base_price: 47.50
                              )

      receipt.add_item(perfume_item)

      expect(receipt.total_tax).to eq(7.15)
    end

    it 'sums the tax amounts of all line items' do
      # book and chocolate bar are tax-exempt (0.0 each), music CD owes 1.50
      receipt.add_item(book_item).add_item(music_cd_item).add_item(chocolate_item)

      expect(receipt.total_tax).to eq(1.50)
    end
  end

  describe '#total_amount' do
    it 'returns 0 when there are no line items' do
      expect(receipt.total_amount).to eq(0)
    end

    it 'returns the shelf price plus tax of a single line item' do
      # 2 * 12.49 = 24.98, no tax
      receipt.add_item(book_item)

      expect(receipt.total_amount).to eq(24.98)
    end

    it 'sums the total price of all line items' do
      # 24.98 (book) + 16.49 (music CD incl. tax) + 0.85 (chocolate bar)
      receipt.add_item(book_item).add_item(music_cd_item).add_item(chocolate_item)

      expect(receipt.total_amount).to eq(42.32)
    end
  end

  describe '#to_s' do
    it 'shows just the tax and total summary when there are no line items' do
      expect(receipt.to_s).to eq("Sales Taxes: 0.00\nTotal: 0.00")
    end

    it 'includes a formatted line for each line item, in order, with tax included in the price' do
      # music CD line price includes its tax: 14.99 + 1.50 = 16.49
      receipt.add_item(book_item).add_item(music_cd_item)

      expect(receipt.to_s).to start_with("2 book: 24.98\n1 music CD: 16.49\n")
    end

    it 'ends with the sales tax and total summary, each with two decimal places' do
      receipt.add_item(book_item).add_item(music_cd_item).add_item(chocolate_item)

      expect(receipt.to_s).to end_with("Sales Taxes: 1.50\nTotal: 42.32")
    end

    it 'matches the full requirements example for Input 1' do
      receipt.add_item(book_item).add_item(music_cd_item).add_item(chocolate_item)

      expected = <<~RECEIPT.chomp
        2 book: 24.98
        1 music CD: 16.49
        1 chocolate bar: 0.85
        Sales Taxes: 1.50
        Total: 42.32
      RECEIPT

      expect(receipt.to_s).to eq(expected)
    end

    it 'matches the full requirements example for Input 2' do
      receipt
        .add_item(line_item(quantity: 1, 
                              description: 'imported box of chocolates', 
                              category: :food, 
                              imported: true,
                              base_price: 10.00
                           )
                  )
        .add_item(line_item(quantity: 1, 
                              description: 'imported bottle of perfume', 
                              category: :other, 
                              imported: true,
                              base_price: 47.50
                           )
                  )

      expected = <<~RECEIPT.chomp
        1 imported box of chocolates: 10.50
        1 imported bottle of perfume: 54.65
        Sales Taxes: 7.65
        Total: 65.15
      RECEIPT

      expect(receipt.to_s).to eq(expected)
    end

    it 'matches the full requirements example for Input 3' do
      receipt
        .add_item(line_item(quantity: 1, 
                            description: 'imported bottle of perfume', 
                            category: :other, 
                            imported: true,
                            base_price: 27.99
                          )
                  )
        .add_item(line_item(quantity: 1, description: 'bottle of perfume', category: :other, base_price: 18.99))
        .add_item(line_item(quantity: 1, description: 'packet of headache pills', category: :medical, base_price: 9.75))
        .add_item(line_item(quantity: 3, 
                            description: 'imported boxes of chocolates', 
                            category: :food, 
                            imported: true,
                            base_price: 11.25
                           )
                  )

      expected = <<~RECEIPT.chomp
        1 imported bottle of perfume: 32.19
        1 bottle of perfume: 20.89
        1 packet of headache pills: 9.75
        3 imported boxes of chocolates: 35.55
        Sales Taxes: 7.90
        Total: 98.38
      RECEIPT

      expect(receipt.to_s).to eq(expected)
    end
  end
end
