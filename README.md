# Cash Register

A Ruby on Rails cash register application with special pricing rules and a React UI for live testing.

**Live Demo: [Cash Register](https://cash-register-gp9f.onrender.com)**

## Features

- **Special Pricing Rules**:
  - Green Tea (GR1): Buy one get one free
  - Strawberries (SR1): €4.50 each when buying 3 or more
  - Coffee (CF1): 2/3 price when buying 3 or more
- **RESTful API** for cart management
- **React UI** for live testing and demonstration
- **Comprehensive test suite** with unit and integration tests

## Project Setup

### Prerequisites

- Ruby 3.3.0
- Rails 8.0
- PostgreSQL 16 database
- Node.js (for React development, optional)

## API Endpoints

### Products
- `GET /products` - List all products

### Carts
- `POST /carts` - Create a new cart
- `GET /carts/:id` - Get cart details
- `DELETE /carts/:id` - Delete a cart

### Cart Products
- `POST /carts/:id/add_product` - Add product to cart
- `PATCH /carts/:id/update_quantity` - Update product quantity
- `DELETE /carts/:id/remove_product` - Remove product from cart

## Discount Logic

The application implements special pricing rules using a strategy pattern:

- **Green Tea (GR1)**: Buy one get one free
- **Strawberries (SR1)**: €4.50 each when buying 3+ items
- **Coffee (CF1)**: 2/3 price when buying 3+ items
