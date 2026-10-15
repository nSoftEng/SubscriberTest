# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/services/tax/tax_calculator'
require_relative '../../../lib/models/product'
require_relative '../../../lib/services/tax/tax_rules/basic_sales_tax_rule'
require_relative '../../../lib/services/tax/tax_rules/import_duty_rule'

RSpec.describe TaxCalculator do
  subject(:calculator) { described_class.new }

  describe '#calculate' do
    describe 'basic sales tax rules' do
      context 'when product is tax-exempt' do
        BasicSalesTaxRule::TAX_EXEMPT_CATEGORIES.each do |category|
          it "does not apply basic sales tax to domestic #{category} products" do
            product = build(:product, category: category, imported: false)
            expect(calculator.calculate(product)).to eq(0.0)
          end
        end
      end

      context 'when product is not tax-exempt' do
        it 'applies basic sales tax to domestic products' do
          product = build(:product, category: :other, imported: false, base_price: 15.00)
          # 15 * 0.10 = 1.50
          expect(calculator.calculate(product)).to eq(1.50)
        end
      end
    end

    describe 'import duty rules' do
      context 'when product is tax-exempt' do
        BasicSalesTaxRule::TAX_EXEMPT_CATEGORIES.each do |category|
          it "applies only import duty to imported #{category} products (no basic sales tax)" do
            product = build(:product, category: category, imported: true, base_price: 10.00)
            # 10.00 * 0.05 = 0.50
            expect(calculator.calculate(product)).to eq(0.50)
          end
        end
      end

      context 'when product is not tax-exempt' do
        it 'applies both basic sales tax and import duty, each rounded independently, then summed' do
          product = build(:product, category: :other, imported: true, base_price: 27.99)
          # basic: 27.99 * 0.10 = 2.799, rounded up to 2.80
          # import: 27.99 * 0.05 = 1.3995, rounded up to 1.40
          # total: 2.80 + 1.40 = 4.20
          expect(calculator.calculate(product)).to be_within(0.001).of(4.20)
        end
      end
    end

    describe 'rounding edge cases' do
      it 'rounds 0.01 up to 0.05' do
        product = build(:product, category: :other, imported: false, base_price: 0.10)
        # 0.10 * 0.10 = 0.01, rounded up to 0.05
        expect(calculator.calculate(product)).to eq(0.05)
      end

      it 'keeps exact 0.05 multiples unchanged' do
        product = build(:product, category: :other, imported: false, base_price: 0.50)
        # 0.50 * 0.10 = 0.05, no rounding needed
        expect(calculator.calculate(product)).to eq(0.05)
      end

      it 'rounds 0.06 up to 0.10' do
        product = build(:product, category: :other, imported: false, base_price: 0.60)
        # 0.60 * 0.10 = 0.06, rounded up to 0.10
        expect(calculator.calculate(product)).to eq(0.10)
      end

      it 'rounds 0.5625 up to 0.60' do
        product = build(:imported_food, base_price: 11.25)
        # 11.25 * 0.05 = 0.5625, rounded up to 0.60
        expect(calculator.calculate(product)).to be_within(0.001).of(0.60)
      end
    end
  end

  describe 'integration with actual tax rules' do
    # These tests verify that the calculator works correctly with the actual BasicSalesTaxRule and ImportDutyRule

    context 'example from requirements - Input 1' do
      it 'calculates correct tax for book' do
        product = build(:domestic_book, base_price: 12.49)
        expect(calculator.calculate(product)).to eq(0.0)
      end

      it 'calculates correct tax for music CD' do
        product = build(:product, description: 'music CD', category: :other, base_price: 14.99)
        expect(calculator.calculate(product)).to eq(1.50)
      end

      it 'calculates correct tax for chocolate bar' do
        product = build(:domestic_food, base_price: 0.85)
        expect(calculator.calculate(product)).to eq(0.0)
      end
    end

    context 'example from requirements - Input 2' do
      it 'calculates correct tax for imported box of chocolates' do
        product = build(:imported_food, description: 'imported box of chocolates', base_price: 10.00)
        expect(calculator.calculate(product)).to eq(0.50)
      end

      it 'calculates correct tax for imported bottle of perfume' do
        product = build(:product, description: 'imported bottle of perfume', category: :other, imported: true, base_price: 47.50)
        # basic: 47.50 * 0.10 = 4.75 (already a multiple of 0.05)
        # import: 47.50 * 0.05 = 2.375, rounded up to 2.40
        # total: 4.75 + 2.40 = 7.15
        expect(calculator.calculate(product)).to eq(7.15)
      end
    end

    context 'example from requirements - Input 3' do
      it 'calculates correct tax for imported bottle of perfume (27.99)' do
        product = build(:product, description: 'imported bottle of perfume', category: :other, imported: true, base_price: 27.99)
        # basic: 27.99 * 0.10 = 2.799, rounded up to 2.80
        # import: 27.99 * 0.05 = 1.3995, rounded up to 1.40
        # total: 2.80 + 1.40 = 4.20
        expect(calculator.calculate(product)).to be_within(0.001).of(4.20)
      end

      it 'calculates correct tax for bottle of perfume (18.99)' do
        product = build(:product, description: 'bottle of perfume', category: :other, base_price: 18.99)
        expect(calculator.calculate(product)).to be_within(0.001).of(1.90)
      end

      it 'calculates correct tax for packet of headache pills' do
        product = build(:domestic_medical, description: 'packet of headache pills', base_price: 9.75)
        expect(calculator.calculate(product)).to eq(0.0)
      end

      it 'calculates correct tax for imported box of chocolates (11.25)' do
        product = build(:imported_food, description: 'imported box of chocolates', base_price: 11.25)
        expect(calculator.calculate(product)).to be_within(0.001).of(0.60)
      end
    end
  end
end
