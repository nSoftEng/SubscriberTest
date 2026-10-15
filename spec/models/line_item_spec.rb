# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/models/line_item'

RSpec.describe LineItem do
  let(:product) { build(:product, base_price: 10.0) }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a line item with all parameters' do
        line_item = LineItem.new(quantity: 2, product:)

        expect(line_item.quantity).to eq(2)
        expect(line_item.product).to eq(product)
      end

      it 'accepts string quantity and converts to integer' do
        line_item = LineItem.new(quantity: '3', product:)
        expect(line_item.quantity).to eq(3)
      end

      it 'treats string quantity with leading zero as decimal' do
        line_item = LineItem.new(quantity: '010', product: product)
        expect(line_item.quantity).to eq(10)
      end
    end

    context 'quantity validation' do
      it 'raises LineItemValidationError when quantity is nil' do
        expect {
          LineItem.new(quantity: nil, product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.value).to be_nil
          expect(error.message).to eq('LineItem quantity cannot be nil')
        end
      end

      it 'raises LineItemValidationError when quantity is zero' do
        expect {
          LineItem.new(quantity: 0, product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.message).to include('must be greater than zero')
        end
      end

      it 'raises LineItemValidationError when quantity is negative' do
        expect {
          LineItem.new(quantity: -1, product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.message).to include('must be greater than zero')
        end
      end

      it 'raises LineItemValidationError when quantity is not a number' do
        expect {
          LineItem.new(quantity: 'abc', product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.message).to include('must be a valid integer')
        end
      end

      it 'raises LineItemValidationError when quantity is a fractional number' do
        expect {
          LineItem.new(quantity: 1.5, product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.message).to include('must be a valid integer')
        end
      end

      it 'raises LineItemValidationError when quantity is an array' do
        expect {
          LineItem.new(quantity: [1], product: product)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:quantity)
          expect(error.message).to include('must be a valid integer')
        end
      end
    end

    context 'product validation' do
      it 'raises LineItemValidationError when product is nil' do
        expect {
          LineItem.new(quantity: 1, product: nil)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:product)
          expect(error.value).to be_nil
          expect(error.message).to eq('LineItem product cannot be nil')
        end
      end

      it 'raises LineItemValidationError when product is not a Product' do
        expect {
          LineItem.new(quantity: 1, product: 'book')
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:product)
          expect(error.value).to eq('book')
          expect(error.message).to include('must be a Product')
        end
      end
    end

    context 'tax_calculator validation' do
      it 'raises LineItemValidationError when tax_calculator is nil' do
        expect {
          LineItem.new(quantity: 1, product: product, tax_calculator: nil)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:tax_calculator)
          expect(error.message).to include('must respond to #calculate')
        end
      end

      it 'raises LineItemValidationError when tax_calculator does not respond to #calculate' do
        expect {
          LineItem.new(quantity: 1, product: product, tax_calculator: Object.new)
        }.to raise_error(LineItemValidationError) do |error|
          expect(error.field).to eq(:tax_calculator)
          expect(error.message).to include('must respond to #calculate')
        end
      end
    end
  end

  describe '#to_s' do
    it 'formats the price including tax when the product is not tax-exempt' do
      # music CD: shelf 14.99 + tax 1.50 = 16.49
      music_cd = build(:product, name: 'music CD', category: :other, base_price: 14.99)
      line_item = LineItem.new(quantity: 1, product: music_cd)

      expect(line_item.to_s).to eq('1 music CD: 16.49')
    end

    it 'formats the shelf price when the product is tax-exempt' do
      line_item = LineItem.new(quantity: 2, product: build(:domestic_book, base_price: 12.49))

      expect(line_item.to_s).to eq('2 book: 24.98')
    end
  end
end
