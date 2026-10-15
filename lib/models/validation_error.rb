# frozen_string_literal: true

class ValidationError < StandardError
  attr_reader :field, :value, :klass

  def initialize(field:, value:, klass:, message:)
    @field = field
    @value = value
    @klass = klass
    super(message)
  end
end
