-- DagaaBook Database Schema for Neon PostgreSQL

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Watumiaji (Users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name VARCHAR(255) NOT NULL DEFAULT '',
  last_name VARCHAR(255) NOT NULL DEFAULT '',
  email VARCHAR(255) DEFAULT '',
  phone VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  business_name VARCHAR(255) DEFAULT '',
  location VARCHAR(255) DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wateja (Customers)
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  location VARCHAR(255) DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mizigo (Stock Items)
CREATE TABLE IF NOT EXISTS stock_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(255) NOT NULL,
  total_magunia INTEGER NOT NULL,
  sold_magunia INTEGER DEFAULT 0,
  purchase_price_per_bag NUMERIC(12, 2) NOT NULL,
  selling_price_per_bag NUMERIC(12, 2) NOT NULL,
  date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  supplier VARCHAR(255) DEFAULT ''
);

-- Mauzo (Sales)
CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  stock_item_id UUID REFERENCES stock_items(id) ON DELETE SET NULL,
  stock_type VARCHAR(255) NOT NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name VARCHAR(255) NOT NULL,
  magunia INTEGER NOT NULL,
  price_per_bag NUMERIC(12, 2) NOT NULL,
  payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('cash', 'mobile', 'credit', 'partial')),
  amount_paid NUMERIC(12, 2) DEFAULT 0,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Malipo (Payments)
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  note TEXT DEFAULT ''
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_stock_item_id ON sales(stock_item_id);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(date);
CREATE INDEX IF NOT EXISTS idx_stock_items_date_added ON stock_items(date_added);
