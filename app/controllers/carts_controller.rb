class CartsController < ApplicationController
  before_action :set_cart, only: %i[ show update destroy add_product remove_product update_quantity ]

  # GET /carts
  def index
    @carts = Cart.all

    render json: @carts
  end

  # GET /carts/1
  def show
    render json: cart_response(@cart)
  end

  # POST /carts
  def create
    @cart = Cart.new(cart_params)

    if @cart.save
      render json: cart_response(@cart), status: :created, location: @cart
    else
      Rails.logger.error "Cart creation failed: #{@cart.errors.full_messages}"
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /carts/1
  def update
    if @cart.update(cart_params)
      @cart.reload
      render json: cart_response(@cart)
    else
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  # POST /carts/1/add_product
  # @param product_id [Integer/String]  the ID of the product to add
  # @param quantity [Integer/String] the quantity of the product to add
  # @return [JSON] the updated cart with the new line item
  def add_product
    product = Product.find(add_or_update_product_params[:product_id])
    quantity = add_or_update_product_params[:quantity] || 1

    # Find existing line item or create new one
    line_item = @cart.line_items.find_or_initialize_by(product: product)
    line_item.quantity = (line_item.quantity || 0) + quantity.to_i

    if line_item.save
      update_cart_totals
      render json: cart_response(@cart)
    else
      render json: line_item.errors, status: :unprocessable_entity
    end
  end

  # DELETE /carts/1/remove_product
  # @param product_id [Integer/String] the ID of the product to remove
  # @return [JSON] the updated cart without the removed line item
  def remove_product
    line_item = @cart.line_items.find_by(product_id: remove_product_params[:product_id])

    if line_item
      line_item.destroy
      update_cart_totals
      render json: cart_response(@cart)
    else
      render json: { error: "Product not found in cart" }, status: :not_found
    end
  end

  # PATCH /carts/1/update_quantity
  # @param product_id [Integer/String] the ID of the product to update
  # @param quantity [Integer/String] the new quantity of the product
  # @return [JSON] the updated cart with the new quantity
  def update_quantity
    line_item = @cart.line_items.find_by(product_id: add_or_update_product_params[:product_id])

    if line_item
      new_quantity = add_or_update_product_params[:quantity].to_i

      if new_quantity <= 0
        line_item.destroy
      else
        line_item.update!(quantity: new_quantity)
      end

      update_cart_totals
      render json: cart_response(@cart)
    else
      render json: { error: "Product not found in cart" }, status: :not_found
    end
  end

  # DELETE /carts/1
  def destroy
    @cart.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cart
      @cart = Cart.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cart_params
      if params[:cart] && params[:cart].present?
        params.require(:cart).permit(line_items_attributes: [ :product_id, :quantity, :_destroy ])
      else
        {} # Allow creating empty carts without any parameters
      end
    end

    # Parameters for adding or updating a product to cart
    def add_or_update_product_params
      params.permit(:product_id, :quantity)
    end

    # Parameters for removing a product from cart
    def remove_product_params
      params.permit(:product_id)
    end

    # Update cart totals and basket
    def update_cart_totals
      @cart.update!(
        total_price: @cart.line_items.sum(&:discounted_subtotal),
        basket: @cart.line_items.map { |item| "#{item.product.code} x #{item.quantity}" }.join(",")
      )
    end

    # Response with calculated totals
    # @param cart [Cart] the cart to respond with
    # @return [JSON] the cart with the calculated totals and line items
    def cart_response(cart)
      cart.as_json.merge(
        calculated_total_price: cart.calculated_total_price,
        line_items: cart.line_items_with_details
      )
    end
end
