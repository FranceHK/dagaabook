-- DagaaBook Seed Data
-- Run AFTER init_schema.sql

-- Wateja (Customers)
INSERT INTO customers (id, name, phone, location, created_at) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Juma Mwakalinga', '0754 112 233', 'Igogo Market', NOW() - INTERVAL '120 days'),
  ('a2222222-2222-2222-2222-222222222222', 'Amina Rashidi', '0765 224 559', 'Mwaloni', NOW() - INTERVAL '95 days'),
  ('a3333333-3333-3333-3333-333333333333', 'Peter Ndege', '0712 998 001', 'Nyamagana', NOW() - INTERVAL '80 days'),
  ('a4444444-4444-4444-4444-444444444444', 'Fatuma Hassani', '0788 445 671', 'Buzuruga', NOW() - INTERVAL '60 days'),
  ('a5555555-5555-5555-5555-555555555555', 'Emmanuel Kissima', '0678 331 902', 'Igoma', NOW() - INTERVAL '45 days'),
  ('a6666666-6666-6666-6666-666666666666', 'Zainabu Omary', '0755 667 812', 'Mkuyuni', NOW() - INTERVAL '30 days'),
  ('a7777777-7777-7777-7777-777777777777', 'Godfrey Mahenge', '0713 556 220', 'Kirumba', NOW() - INTERVAL '15 days');

-- Mizigo (Stock Items)
INSERT INTO stock_items (id, type, total_magunia, sold_magunia, purchase_price_per_bag, selling_price_per_bag, date_added, supplier) VALUES
  ('b1111111-1111-1111-1111-111111111111', 'Dagaa Kavu - Ziwa Victoria', 20, 7, 130000, 160000, NOW() - INTERVAL '2 days', 'Kirumba Beach Suppliers'),
  ('b2222222-2222-2222-2222-222222222222', 'Dagaa wa Chumvi', 10, 4, 116000, 145000, NOW() - INTERVAL '5 days', 'Mwaloni Fishers Co-op'),
  ('b3333333-3333-3333-3333-333333333333', 'Dagaa Kavu - Daraja A', 25, 9, 144000, 178000, NOW() - INTERVAL '9 days', 'Igombe Traders'),
  ('b4444444-4444-4444-4444-444444444444', 'Dagaa Mchanganyiko', 8, 8, 104000, 130000, NOW() - INTERVAL '14 days', 'Kirumba Beach Suppliers');

-- Mauzo (Sales)
INSERT INTO sales (id, stock_item_id, stock_type, customer_id, customer_name, magunia, price_per_bag, payment_type, amount_paid, date) VALUES
  ('c1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Dagaa Kavu - Ziwa Victoria', 'a1111111-1111-1111-1111-111111111111', 'Juma Mwakalinga', 3, 160000, 'partial', 300000, NOW()),
  ('c2222222-2222-2222-2222-222222222222', 'b1111111-1111-1111-1111-111111111111', 'Dagaa Kavu - Ziwa Victoria', NULL, 'Mteja wa Kawaida', 1, 160000, 'cash', 160000, NOW()),
  ('c3333333-3333-3333-3333-333333333333', 'b3333333-3333-3333-3333-333333333333', 'Dagaa Kavu - Daraja A', 'a2222222-2222-2222-2222-222222222222', 'Amina Rashidi', 4, 178000, 'partial', 400000, NOW() - INTERVAL '1 day'),
  ('c4444444-4444-4444-4444-444444444444', 'b2222222-2222-2222-2222-222222222222', 'Dagaa wa Chumvi', 'a3333333-3333-3333-3333-333333333333', 'Peter Ndege', 2, 145000, 'mobile', 290000, NOW() - INTERVAL '1 day'),
  ('c5555555-5555-5555-5555-555555555555', 'b3333333-3333-3333-3333-333333333333', 'Dagaa Kavu - Daraja A', 'a4444444-4444-4444-4444-444444444444', 'Fatuma Hassani', 3, 178000, 'credit', 0, NOW() - INTERVAL '2 days'),
  ('c6666666-6666-6666-6666-666666666666', 'b1111111-1111-1111-1111-111111111111', 'Dagaa Kavu - Ziwa Victoria', 'a1111111-1111-1111-1111-111111111111', 'Juma Mwakalinga', 2, 160000, 'credit', 0, NOW() - INTERVAL '3 days'),
  ('c7777777-7777-7777-7777-777777777777', 'b4444444-4444-4444-4444-444444444444', 'Dagaa Mchanganyiko', 'a5555555-5555-5555-5555-555555555555', 'Emmanuel Kissima', 4, 130000, 'cash', 520000, NOW() - INTERVAL '3 days'),
  ('c8888888-8888-8888-8888-888888888888', 'b2222222-2222-2222-2222-222222222222', 'Dagaa wa Chumvi', 'a2222222-2222-2222-2222-222222222222', 'Amina Rashidi', 1, 145000, 'partial', 60000, NOW() - INTERVAL '4 days'),
  ('c9999999-9999-9999-9999-999999999999', 'b3333333-3333-3333-3333-333333333333', 'Dagaa Kavu - Daraja A', 'a6666666-6666-6666-6666-666666666666', 'Zainabu Omary', 2, 178000, 'partial', 100000, NOW() - INTERVAL '5 days'),
  ('ca111111-1111-1111-1111-111111111111', 'b4444444-4444-4444-4444-444444444444', 'Dagaa Mchanganyiko', 'a7777777-7777-7777-7777-777777777777', 'Godfrey Mahenge', 4, 130000, 'credit', 0, NOW() - INTERVAL '6 days'),
  ('ca222222-2222-2222-2222-222222222222', 'b1111111-1111-1111-1111-111111111111', 'Dagaa Kavu - Ziwa Victoria', NULL, 'Mteja wa Kawaida', 1, 160000, 'mobile', 160000, NOW() - INTERVAL '6 days'),
  ('ca333333-3333-3333-3333-333333333333', 'b2222222-2222-2222-2222-222222222222', 'Dagaa wa Chumvi', 'a3333333-3333-3333-3333-333333333333', 'Peter Ndege', 1, 145000, 'partial', 50000, NOW() - INTERVAL '7 days');

-- Malipo (Payments)
INSERT INTO payments (id, customer_id, amount, date, note) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 50000, NOW() - INTERVAL '1 day', 'Malipo ya awali'),
  ('d2222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 80000, NOW() - INTERVAL '2 days', ''),
  ('d4444444-4444-4444-4444-444444444444', 'a4444444-4444-4444-4444-444444444444', 100000, NOW() - INTERVAL '1 day', '');
