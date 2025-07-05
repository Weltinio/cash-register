class Cart < ApplicationRecord
  has_many :line_items
  has_many :products, through: :line_items

  # Calculate the current total price from line items
  # @return [Float] the total price of all line items
  def calculated_total_price
    line_items.sum(&:discounted_subtotal)
  end

  # Get line items with product details
  # @return [Array<Hash>] the line items with product details
  def line_items_with_details
    line_items.includes(:product).map do |line_item|
      {
        id: line_item.id,
        product_id: line_item.product_id,
        product_code: line_item.product.code,
        product_name: line_item.product.name,
        quantity: line_item.quantity,
        unit_price: line_item.product.price,
        subtotal: line_item.subtotal,
        discounted_subtotal: line_item.discounted_subtotal
      }
    end
  end
end
