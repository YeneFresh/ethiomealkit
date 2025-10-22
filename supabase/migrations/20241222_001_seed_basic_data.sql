-- Seed basic data for the app to work
-- Add some sample meal kits and delivery windows

-- Insert sample meal kits
INSERT INTO public.meal_kits (id, title, description, price_cents, image_url) VALUES
('doro-wat', 'Doro Wat', 'Traditional Ethiopian chicken stew with berbere spice', 1200, 'assets/images/doro-wat.jpg'),
('injera-combo', 'Injera Combo', 'Fresh injera with assorted vegetarian dishes', 800, 'assets/images/injera-combo.jpg'),
('tibs-special', 'Tibs Special', 'Sautéed beef with onions and peppers', 1500, 'assets/images/tibs-special.jpg')
ON CONFLICT (id) DO NOTHING;

-- Insert delivery windows
INSERT INTO public.delivery_windows (id, label, day_of_week, start_time, end_time) VALUES
('tue_afternoon', 'Tuesday Afternoon', 'Tuesday', '15:00', '18:00'),
('wed_afternoon', 'Wednesday Afternoon', 'Wednesday', '15:00', '18:00'),
('thu_afternoon', 'Thursday Afternoon', 'Thursday', '15:00', '18:00')
ON CONFLICT (id) DO NOTHING;

SELECT 'Sample data seeded successfully' as status;
