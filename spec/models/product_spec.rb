# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/models/product'

RSpec.describe Product do
  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a product with all parameters' do
        product = Product.new(
          description: 'Test Product',
          base_price: 10.99,
          category: :book,
          imported: true
        )

        expect(product.description).to eq('Test Product')
        expect(product.base_price).to eq(10.99)
        expect(product.category).to eq(:book)
        expect(product.imported).to eq(true)
      end

      it 'accepts string price and converts to float' do
        product = Product.new(description: 'Product', base_price: '15.50')
        expect(product.base_price).to eq(15.50)
      end

      it 'accepts integer price and converts to float' do
        product = Product.new(description: 'Product', base_price: 20)
        expect(product.base_price).to eq(20.0)
      end

      it 'strips whitespace from description' do
        product = Product.new(description: '  Product Description  ', base_price: 10.0)
        expect(product.description).to eq('Product Description')
      end

      it 'accepts zero as valid price' do
        product = Product.new(description: 'Free Product', base_price: 0)
        expect(product.base_price).to eq(0.0)
      end
    end

    context 'description validation' do
      it 'raises ProductValidationError when description is nil' do
        expect {
          Product.new(description: nil, base_price: 10.0)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:description)
          expect(error.value).to be_nil
          expect(error.klass).to eq(Product)
          expect(error.message).to eq('Description cannot be nil')
        end
      end

      it 'raises ProductValidationError when description is only whitespace' do
        expect {
          Product.new(description: '   ', base_price: 10.0)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:description)
          expect(error.message).to eq('Description cannot be empty')
        end
      end
    end

    context 'base_price validation' do
      it 'raises ProductValidationError when price is nil' do
        expect {
          Product.new(description: 'Product', base_price: nil)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:base_price)
          expect(error.value).to be_nil
          expect(error.message).to eq('Base price cannot be nil')
        end
      end

      it 'raises ProductValidationError when price is negative' do
        expect {
          Product.new(description: 'Product', base_price: -5.0)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:base_price)
          expect(error.message).to include('cannot be negative')
        end
      end

      it 'raises ProductValidationError when price is not a number' do
        expect {
          Product.new(description: 'Product', base_price: 'invalid')
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:base_price)
          expect(error.message).to include('must be a valid number')
        end
      end

      it 'raises ProductValidationError when price is an array' do
        expect {
          Product.new(description: 'Product', base_price: [10])
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:base_price)
          expect(error.message).to include('must be a valid number')
        end
      end
    end

    context 'category validation' do
      it 'raises ProductValidationError for invalid category' do
        expect {
          Product.new(description: 'Product', base_price: 10.0, category: :invalid)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:category)
          expect(error.value).to eq(:invalid)
          expect(error.message).to include('Invalid category')
          expect(error.message).to include('book, food, medical, other')
        end
      end

      it 'accepts all valid categories' do
        valid_categories = %i[book food medical other]

        valid_categories.each do |category|
          expect {
            Product.new(description: 'Product', base_price: 10.0, category: category)
          }.not_to raise_error
        end
      end
    end

    context 'imported validation' do
      it 'raises ProductValidationError when imported is not boolean' do
        expect {
          Product.new(description: 'Product', base_price: 10.0, imported: 'yes')
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:imported)
          expect(error.message).to include('must be true or false')
        end
      end

      it 'raises ProductValidationError when imported is nil' do
        expect {
          Product.new(description: 'Product', base_price: 10.0, imported: nil)
        }.to raise_error(ProductValidationError) do |error|
          expect(error.field).to eq(:imported)
          expect(error.message).to include('must be true or false')
        end
      end

      it 'accepts true' do
        expect {
          Product.new(description: 'Product', base_price: 10.0, imported: true)
        }.not_to raise_error
      end

      it 'accepts false' do
        expect {
          Product.new(description: 'Product', base_price: 10.0, imported: false)
        }.not_to raise_error
      end
    end
  end
end
