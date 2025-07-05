require 'rails_helper'

RSpec.describe 'Cart Discount Logic', type: :model do
  let(:green_tea) { Product.find_by(code: 'GR1') || Product.create!(code: 'GR1', name: 'Green Tea', price: 3.11) }
  let(:strawberries) { Product.find_by(code: 'SR1') || Product.create!(code: 'SR1', name: 'Strawberries', price: 5.00) }
  let(:coffee) { Product.find_by(code: 'CF1') || Product.create!(code: 'CF1', name: 'Coffee', price: 11.23) }

  describe 'Discount calculations' do
    it 'calculates buy-one-get-one-free for green tea' do
      cart = Cart.create!
      line_item = LineItem.create!(cart: cart, product: green_tea, quantity: 2)

      expect(line_item.discounted_subtotal).to eq(3.11) # Pay for 1, get 1 free
    end

    it 'calculates bulk discount for strawberries (3+ items)' do
      cart = Cart.create!
      line_item = LineItem.create!(cart: cart, product: strawberries, quantity: 3)

      expect(line_item.discounted_subtotal).to eq(13.50) # 3 * 4.50
    end

    it 'calculates bulk discount for coffee (3+ items)' do
      cart = Cart.create!
      line_item = LineItem.create!(cart: cart, product: coffee, quantity: 3)

      expected = (7.49 * 3).round(2)
      expect(line_item.discounted_subtotal).to eq(expected)
    end

    it 'applies no discount for quantities below threshold' do
      cart = Cart.create!
      line_item = LineItem.create!(cart: cart, product: strawberries, quantity: 2)

      expect(line_item.discounted_subtotal).to eq(10.00) # Regular price: 2 * 5.00
    end

    it 'calculates complex cart with all discounts' do
      cart = Cart.create!
      LineItem.create!(cart: cart, product: green_tea, quantity: 3)
      LineItem.create!(cart: cart, product: strawberries, quantity: 1)
      LineItem.create!(cart: cart, product: coffee, quantity: 1)

      expected_total = 6.22 + 5.00 + 11.23 # 2 paid green tea + regular strawberries + regular coffee
      expect(cart.calculated_total_price).to eq(expected_total)
    end
  end

  describe 'Line item calculations' do
    it 'calculates subtotal correctly' do
      cart = Cart.create!
      line_item = LineItem.create!(cart: cart, product: green_tea, quantity: 3)

      expect(line_item.subtotal).to eq(9.33) # 3 * 3.11
    end

    it 'handles different discount strategies' do
      cart = Cart.create!

      # Test each discount strategy
      gr1_item = LineItem.create!(cart: cart, product: green_tea, quantity: 2)
      sr1_item = LineItem.create!(cart: cart, product: strawberries, quantity: 3)
      cf1_item = LineItem.create!(cart: cart, product: coffee, quantity: 3)

      expect(gr1_item.discounted_subtotal).to eq(3.11) # BOGO
      expect(sr1_item.discounted_subtotal).to eq(13.50) # Bulk discount
      expect(cf1_item.discounted_subtotal).to eq(22.47) # 3 * 7.49
    end
  end
end
