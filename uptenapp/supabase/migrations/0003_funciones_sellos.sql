-- UpTen · Migración 3: funciones para sumar sello, canjear y deshacer
-- Se hacen dentro de la base de datos para que dos escaneos al mismo tiempo no se pisen.
-- Solo el servidor (llave de servicio) puede llamarlas.

-- Sumar un sello
create function public.stamp_card(p_serial text, p_employee_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  c public.cards;
  b public.businesses;
  e public.employees;
  cust_name text;
  last_stamp timestamptz;
  wait_seconds int;
  ev uuid;
begin
  select * into c from public.cards where serial = p_serial for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'not_found'); end if;

  select * into b from public.businesses where id = c.business_id;
  if b.status <> 'active' then return jsonb_build_object('ok', false, 'error', 'paused'); end if;

  select * into e from public.employees where id = p_employee_id and active and business_id = c.business_id;
  if not found then return jsonb_build_object('ok', false, 'error', 'forbidden'); end if;

  select name into cust_name from public.customers where id = c.customer_id;

  -- Cooldown: último sello que no fue deshecho
  select max(s.created_at) into last_stamp
  from public.stamp_events s
  where s.card_id = c.id and s.type = 'stamp'
    and not exists (select 1 from public.stamp_events u where u.undoes_event_id = s.id);

  if last_stamp is not null and last_stamp > now() - make_interval(mins => b.cooldown_minutes) then
    wait_seconds := ceil(extract(epoch from (last_stamp + make_interval(mins => b.cooldown_minutes) - now())))::int;
    return jsonb_build_object('ok', false, 'error', 'cooldown', 'retry_seconds', wait_seconds,
      'customer_name', cust_name, 'stamps', c.stamps, 'required', b.stamps_required);
  end if;

  insert into public.stamp_events (card_id, employee_id, type) values (c.id, p_employee_id, 'stamp') returning id into ev;
  update public.cards set stamps = stamps + 1, last_visit_at = now() where id = c.id returning * into c;

  return jsonb_build_object('ok', true, 'event_id', ev, 'card_id', c.id, 'customer_name', cust_name,
    'stamps', c.stamps, 'required', b.stamps_required);
end $$;

-- Canjear la recompensa (resta los sellos requeridos, conserva el sobrante)
create function public.redeem_card(p_serial text, p_employee_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  c public.cards;
  b public.businesses;
  e public.employees;
  cust_name text;
  ev uuid;
begin
  select * into c from public.cards where serial = p_serial for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'not_found'); end if;

  select * into b from public.businesses where id = c.business_id;
  if b.status <> 'active' then return jsonb_build_object('ok', false, 'error', 'paused'); end if;

  select * into e from public.employees where id = p_employee_id and active and business_id = c.business_id;
  if not found then return jsonb_build_object('ok', false, 'error', 'forbidden'); end if;

  select name into cust_name from public.customers where id = c.customer_id;

  if c.stamps < b.stamps_required then
    return jsonb_build_object('ok', false, 'error', 'not_enough', 'customer_name', cust_name,
      'stamps', c.stamps, 'required', b.stamps_required);
  end if;

  insert into public.stamp_events (card_id, employee_id, type) values (c.id, p_employee_id, 'redeem') returning id into ev;
  update public.cards set stamps = stamps - b.stamps_required, last_visit_at = now() where id = c.id returning * into c;

  return jsonb_build_object('ok', true, 'event_id', ev, 'card_id', c.id, 'customer_name', cust_name,
    'stamps', c.stamps, 'required', b.stamps_required);
end $$;

-- Deshacer la última acción (solo si fue hace menos de 2 minutos)
create function public.undo_last(p_serial text, p_employee_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  c public.cards;
  b public.businesses;
  e public.employees;
  last_ev public.stamp_events;
  cust_name text;
begin
  select * into c from public.cards where serial = p_serial for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'not_found'); end if;

  select * into b from public.businesses where id = c.business_id;
  select * into e from public.employees where id = p_employee_id and active and business_id = c.business_id;
  if not found then return jsonb_build_object('ok', false, 'error', 'forbidden'); end if;

  select * into last_ev from public.stamp_events s
  where s.card_id = c.id and s.type in ('stamp', 'redeem')
    and not exists (select 1 from public.stamp_events u where u.undoes_event_id = s.id)
  order by s.created_at desc limit 1;

  if not found or last_ev.created_at < now() - interval '2 minutes' then
    return jsonb_build_object('ok', false, 'error', 'nothing_to_undo');
  end if;

  select name into cust_name from public.customers where id = c.customer_id;

  insert into public.stamp_events (card_id, employee_id, type, undoes_event_id)
  values (c.id, p_employee_id, 'undo', last_ev.id);

  if last_ev.type = 'stamp' then
    update public.cards set stamps = greatest(stamps - 1, 0) where id = c.id returning * into c;
  else
    update public.cards set stamps = stamps + b.stamps_required where id = c.id returning * into c;
  end if;

  return jsonb_build_object('ok', true, 'card_id', c.id, 'customer_name', cust_name,
    'stamps', c.stamps, 'required', b.stamps_required);
end $$;

-- Solo el servidor puede llamarlas
revoke all on function public.stamp_card(text, uuid) from public, anon, authenticated;
revoke all on function public.redeem_card(text, uuid) from public, anon, authenticated;
revoke all on function public.undo_last(text, uuid) from public, anon, authenticated;
grant execute on function public.stamp_card(text, uuid) to service_role;
grant execute on function public.redeem_card(text, uuid) to service_role;
grant execute on function public.undo_last(text, uuid) to service_role;
