require 'rails_helper'

RSpec.describe 'Cart Integration', type: :request do
  let(:green_tea) { Product.find_by(code: 'GR1') || Product.create!(code: 'GR1', name: 'Green Tea', price: 3.11) }
  let(:strawberries) { Product.find_by(code: 'SR1') || Product.create!(code: 'SR1', name: 'Strawberries', price: 5.00) }
  let(:coffee) { Product.find_by(code: 'CF1') || Product.create!(code: 'CF1', name: 'Coffee', price: 11.23) }

  describe 'Cart lifecycle' do
    it 'creates a cart and adds products through API' do
      # Create a cart
      post '/carts'
      expect(response).to have_http_status(:created)
      cart = JSON.parse(response.body)
      cart_id = cart['id']

      # Add green tea to cart
      post "/carts/#{cart_id}/add_product", params: { product_id: green_tea.id, quantity: 2 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(3.11) # BOGO discount
      expect(cart_response['basket']).to eq('GR1 x 2')

      # Add strawberries to cart
      post "/carts/#{cart_id}/add_product", params: { product_id: strawberries.id, quantity: 3 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(16.61) # 3.11 + (3 * 4.50)
      expect(cart_response['basket']).to eq('GR1 x 2,SR1 x 3')

      # Add coffee to cart
      post "/carts/#{cart_id}/add_product", params: { product_id: coffee.id, quantity: 3 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expected_total = 3.11 + (3 * 4.50) + (3 * 7.49)
      expect(cart_response['calculated_total_price'].to_f).to eq(expected_total)
      expect(cart_response['basket']).to eq('GR1 x 2,SR1 x 3,CF1 x 3')
    end

    it 'updates product quantities through API' do
      # Create cart and add products
      post '/carts'
      cart_id = JSON.parse(response.body)['id']

      post "/carts/#{cart_id}/add_product", params: { product_id: green_tea.id, quantity: 2 }
      post "/carts/#{cart_id}/add_product", params: { product_id: strawberries.id, quantity: 3 }

      # Update green tea quantity
      patch "/carts/#{cart_id}/update_quantity", params: { product_id: green_tea.id, quantity: 1 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(16.61) # 3.11 + (3 * 4.50)
      expect(cart_response['basket']).to eq('GR1 x 1,SR1 x 3')

      # Update strawberries quantity to remove bulk discount
      patch "/carts/#{cart_id}/update_quantity", params: { product_id: strawberries.id, quantity: 2 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(13.11) # 3.11 + (2 * 5.00)
      expect(cart_response['basket']).to eq('GR1 x 1,SR1 x 2')
    end

    it 'removes products from cart through API' do
      # Create cart and add products
      post '/carts'
      cart_id = JSON.parse(response.body)['id']

      post "/carts/#{cart_id}/add_product", params: { product_id: green_tea.id, quantity: 2 }
      post "/carts/#{cart_id}/add_product", params: { product_id: strawberries.id, quantity: 3 }

      # Remove strawberries
      delete "/carts/#{cart_id}/remove_product", params: { product_id: strawberries.id }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(3.11) # Only green tea with BOGO
      expect(cart_response['basket']).to eq('GR1 x 2')
      expect(cart_response['line_items'].length).to eq(1)
    end

    it 'removes line item when quantity is set to 0' do
      # Create cart and add products
      post '/carts'
      cart_id = JSON.parse(response.body)['id']

      post "/carts/#{cart_id}/add_product", params: { product_id: green_tea.id, quantity: 2 }

      # Set quantity to 0
      patch "/carts/#{cart_id}/update_quantity", params: { product_id: green_tea.id, quantity: 0 }
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['calculated_total_price'].to_f).to eq(0)
      expect(cart_response['basket']).to eq('')
      expect(cart_response['line_items'].length).to eq(0)
    end

    it 'handles invalid product requests gracefully' do
      post '/carts'
      cart_id = JSON.parse(response.body)['id']

      # Try to remove non-existent product
      delete "/carts/#{cart_id}/remove_product", params: { product_id: 999 }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Product not found in cart')

      # Try to update quantity of non-existent product
      patch "/carts/#{cart_id}/update_quantity", params: { product_id: 999, quantity: 1 }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Product not found in cart')
    end

    it 'shows cart details with line items' do
      # Create cart and add products
      post '/carts'
      cart_id = JSON.parse(response.body)['id']

      post "/carts/#{cart_id}/add_product", params: { product_id: green_tea.id, quantity: 2 }
      post "/carts/#{cart_id}/add_product", params: { product_id: strawberries.id, quantity: 3 }

      # Get cart details
      get "/carts/#{cart_id}"
      expect(response).to have_http_status(:ok)

      cart_response = JSON.parse(response.body)
      expect(cart_response['line_items']).to be_present
      expect(cart_response['line_items'].length).to eq(2)

      # Check line item details
      green_tea_item = cart_response['line_items'].find { |item| item['product_code'] == 'GR1' }
      expect(green_tea_item['product_name']).to eq('Green Tea')
      expect(green_tea_item['quantity'].to_i).to eq(2)
      expect(green_tea_item['unit_price'].to_f).to eq(3.11)
      expect(green_tea_item['discounted_subtotal'].to_f).to eq(3.11) # BOGO discount
    end
  end
end
