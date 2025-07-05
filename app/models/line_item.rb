class LineItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  # Discount strategies for different product types
  DISCOUNT_STRATEGIES = {
    "GR1" => :buy_one_get_one_free,
    "SR1" => :bulk_discount_strawberries,
    "CF1" => :bulk_discount_coffee
  }.freeze

  # Calculate the subtotal based on the product price and quantity
  # @return [Float] the subtotal
  def subtotal
    (product.price * quantity).round(2)
  end

  # Calculate the discounted subtotal based on the product code
  # @return [Float] either the discounted subtotal or the subtotal
  def discounted_subtotal
    strategy = DISCOUNT_STRATEGIES[product.code]
    strategy ? send(strategy) : subtotal
  end

  private

  # Buy-one-get-one-free: pay for every other item
  # @return [Float] the discounted subtotal
  def buy_one_get_one_free
    paid_quantity = (quantity + 1) / 2
    (product.price * paid_quantity).round(2)
  end

  # Bulk discount for strawberries: 4.50 each when 3+ items
  # @return [Float] the discounted subtotal
  def bulk_discount_strawberries
    return subtotal unless quantity >= 3

    (quantity * 4.50).round(2)
  end

  # Bulk discount for coffee: 2/3 price (7.49) when 3+ items
  # @return [Float] the discounted subtotal
  def bulk_discount_coffee
    return subtotal unless quantity >= 3

    (quantity * 7.49).round(2)
  end
end
