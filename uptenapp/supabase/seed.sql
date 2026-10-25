-- UpTen · Datos de prueba: negocio "Café Demo"
-- SOLO para pruebas. No lo corras en tu base de datos real de producción con clientes.
-- Empleado demo: PIN 1234

insert into public.businesses (slug, name, brand_color, text_color, stamps_required, reward_text, terms_text, contact_text)
values (
  'cafe-demo', 'Café Demo', '#6F4E37', '#FFFFFF', 8, 'Un café americano gratis',
  'Un sello por visita. Un solo sello cada 10 minutos. No acumulable con otras promociones.',
  'Café Demo · Calle Ejemplo 123, CDMX'
) on conflict (slug) do nothing;

insert into public.employees (business_id, name, pin_hash)
select id, 'Empleado Demo', '$2b$10$OZl4vn7AoEYY1AtDj2qMs.HxM2UyX7xJcrCJBFgOgg3wVMTZcWSzu'
from public.businesses where slug = 'cafe-demo'
and not exists (select 1 from public.employees e where e.business_id = businesses.id);

insert into public.customers (business_id, name, phone)
select id, 'Cliente Demo', '5512345678' from public.businesses where slug = 'cafe-demo'
on conflict (business_id, phone) do nothing;

insert into public.cards (business_id, customer_id, stamps)
select c.business_id, c.id, 3 from public.customers c
join public.businesses b on b.id = c.business_id
where b.slug = 'cafe-demo' and c.phone = '5512345678'
on conflict (customer_id) do nothing;
