-- UpTen · Migración 2: seguridad (RLS)
-- Regla: un dueño solo puede ver y editar SU negocio.
-- El escáner, el alta de clientes y Wallet NO usan estas reglas: pasan por el servidor con llave de servicio.

alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.employees enable row level security;
alter table public.customers enable row level security;
alter table public.cards enable row level security;
alter table public.stamp_events enable row level security;
alter table public.device_registrations enable row level security;
alter table public.login_attempts enable row level security;

-- ¿El usuario actual es dueño de este negocio?
create function public.is_member(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.business_members
    where business_id = b and user_id = auth.uid()
  );
$$;

-- Negocios: el dueño ve y edita el suyo (los campos de cobro los edita solo el admin, desde el servidor)
create policy "dueño ve su negocio" on public.businesses
  for select to authenticated using (public.is_member(id));
create policy "dueño edita su negocio" on public.businesses
  for update to authenticated using (public.is_member(id)) with check (public.is_member(id));

create policy "ve sus membresías" on public.business_members
  for select to authenticated using (user_id = auth.uid());

-- Empleados: el dueño los gestiona
create policy "dueño ve empleados" on public.employees
  for select to authenticated using (public.is_member(business_id));
create policy "dueño crea empleados" on public.employees
  for insert to authenticated with check (public.is_member(business_id));
create policy "dueño edita empleados" on public.employees
  for update to authenticated using (public.is_member(business_id)) with check (public.is_member(business_id));

-- Clientes, tarjetas y sellos: el dueño solo lee
create policy "dueño ve clientes" on public.customers
  for select to authenticated using (public.is_member(business_id));
create policy "dueño ve tarjetas" on public.cards
  for select to authenticated using (public.is_member(business_id));
create policy "dueño ve sellos" on public.stamp_events
  for select to authenticated using (
    exists (select 1 from public.cards c where c.id = card_id and public.is_member(c.business_id))
  );

-- device_registrations y login_attempts: sin políticas = nadie desde el navegador (solo el servidor)

-- El dueño NO puede cambiar los campos de cobro/admin aunque edite su negocio
create function public.proteger_campos_admin() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and auth.role() = 'authenticated' then
    new.slug = old.slug;
    new.status = old.status;
    new.plan_status = old.plan_status;
    new.next_payment_date = old.next_payment_date;
    new.admin_notes = old.admin_notes;
  end if;
  return new;
end $$;

create trigger businesses_proteger before update on public.businesses
for each row execute function public.proteger_campos_admin();

-- Logos: carpeta pública; solo el dueño sube archivos dentro de la carpeta de su negocio
insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

create policy "logos públicos" on storage.objects
  for select using (bucket_id = 'logos');
create policy "dueño sube logo" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
    and public.is_member(((storage.foldername(name))[1])::uuid)
  );
create policy "dueño reemplaza logo" on storage.objects
  for update to authenticated using (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
    and public.is_member(((storage.foldername(name))[1])::uuid)
  );
create policy "dueño borra logo" on storage.objects
  for delete to authenticated using (
    bucket_id = 'logos'
    and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
    and public.is_member(((storage.foldername(name))[1])::uuid)
  );
