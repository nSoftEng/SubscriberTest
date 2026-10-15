# frozen_string_literal: true

require_relative '../../lib/models/product'

FactoryBot.define do
  factory :product, class: Product do
    transient do
      name { 'Generic Product' }
      base_price { rand(1.0..100.0).round(2) }
      category { :other }
      imported { false }
    end

    initialize_with { new(name: name, base_price: base_price, category: category, imported: imported) }

    trait :book do
      category { :book }
      name { 'book' }
    end

    trait :food do
      category { :food }
      name { 'chocolate bar' }
    end

    trait :medical do
      category { :medical }
      name { 'headache pills' }
    end

    trait :imported do
      imported { true }
    end

    trait :other do
      category { :other }
    end

    # Specific product factories
    factory :domestic_book, traits: [:book]
    factory :domestic_food, traits: [:food]
    factory :domestic_medical, traits: [:medical]
    factory :imported_book, traits: [:book, :imported]
    factory :imported_food, traits: [:food, :imported]
    factory :imported_medical, traits: [:medical, :imported]
  end
end
