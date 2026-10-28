-- GridLearn: esquema relacional para Supabase (PostgreSQL 15+).
--
-- Cada usuario (auth.users, gestionado por Supabase Auth) tiene sus propios
-- vocabularios, y cada vocabulario tiene sus palabras:
--
--   auth.users 1 ──< vocabularies 1 ──< vocabulary_words
--
-- Seguridad: Row Level Security en todas las tablas. Un usuario solo puede ver,
-- crear, modificar y borrar sus propias filas; el rol `anon` no tiene acceso.
-- La clave pública (anon key) que usa la app es segura porque estas políticas
-- se aplican en la base de datos, no en el cliente.

-- ---------------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------------

create table public.vocabularies (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  -- El título es opcional: cadena vacía = "Sin título".
  title      text not null default '' check (char_length(title) <= 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Permite que vocabulary_words referencie (id, user_id) y así una palabra
  -- nunca pueda colgar del vocabulario de otro usuario.
  unique (id, user_id)
);

comment on table public.vocabularies is 'Vocabularios (grillas de bingo) guardados por cada usuario.';

create index vocabularies_user_updated_idx
  on public.vocabularies (user_id, updated_at desc);

create table public.vocabulary_words (
  id            uuid primary key default gen_random_uuid(),
  vocabulary_id uuid not null,
  user_id       uuid not null default auth.uid(),
  -- Orden de la palabra dentro del vocabulario (0 = primera casilla).
  position      integer not null check (position >= 0),
  english       text not null check (char_length(btrim(english)) between 1 and 120),
  spanish       text not null check (char_length(btrim(spanish)) between 1 and 120),
  phonetic      text not null default '' check (char_length(phonetic) <= 120),
  created_at    timestamptz not null default now(),
  foreign key (vocabulary_id, user_id)
    references public.vocabularies (id, user_id) on delete cascade,
  unique (vocabulary_id, position)
);

comment on table public.vocabulary_words is 'Palabras de un vocabulario: inglés, traducción y fonética.';

-- ---------------------------------------------------------------------------
-- Triggers: updated_at y límites por usuario (evitan abuso del almacenamiento)
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger vocabularies_set_updated_at
  before update on public.vocabularies
  for each row execute function public.set_updated_at();

create function public.enforce_vocabulary_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.vocabularies where user_id = new.user_id) >= 100 then
    raise exception 'Se alcanzó el máximo de 100 vocabularios por usuario'
      using errcode = '54000';
  end if;
  return new;
end;
$$;

create trigger vocabularies_enforce_limit
  before insert on public.vocabularies
  for each row execute function public.enforce_vocabulary_limit();

create function public.enforce_word_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.vocabulary_words where vocabulary_id = new.vocabulary_id) >= 500 then
    raise exception 'Se alcanzó el máximo de 500 palabras por vocabulario'
      using errcode = '54000';
  end if;
  return new;
end;
$$;

create trigger vocabulary_words_enforce_limit
  before insert on public.vocabulary_words
  for each row execute function public.enforce_word_limit();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.vocabularies enable row level security;
alter table public.vocabulary_words enable row level security;

-- (select auth.uid()) se evalúa una sola vez por consulta (más rápido).
create policy "vocabularies: el dueño lee"
  on public.vocabularies for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "vocabularies: el dueño crea"
  on public.vocabularies for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "vocabularies: el dueño modifica"
  on public.vocabularies for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "vocabularies: el dueño borra"
  on public.vocabularies for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "vocabulary_words: el dueño lee"
  on public.vocabulary_words for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "vocabulary_words: el dueño crea"
  on public.vocabulary_words for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "vocabulary_words: el dueño modifica"
  on public.vocabulary_words for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "vocabulary_words: el dueño borra"
  on public.vocabulary_words for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Privilegios: nada para visitantes anónimos, solo lo necesario para usuarios
-- con sesión (las políticas de arriba filtran las filas).
revoke all on public.vocabularies from anon, public;
revoke all on public.vocabulary_words from anon, public;
grant select, insert, update, delete on public.vocabularies to authenticated;
grant select, insert, update, delete on public.vocabulary_words to authenticated;

-- ---------------------------------------------------------------------------
-- Guardado atómico: crea o actualiza un vocabulario y reemplaza sus palabras
-- en una sola transacción. Se ejecuta con los permisos de quien llama
-- (security invoker), así que RLS sigue aplicándose.
--
-- p_words: [{"english": "...", "spanish": "...", "phonetic": "..."}, ...]
-- El orden del arreglo define la posición (casilla) de cada palabra.
-- ---------------------------------------------------------------------------

create function public.save_vocabulary(
  p_id    uuid,
  p_title text,
  p_words jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Se requiere iniciar sesión' using errcode = '28000';
  end if;

  if p_words is null or jsonb_typeof(p_words) <> 'array' then
    raise exception 'p_words debe ser un arreglo JSON' using errcode = '22023';
  end if;

  if jsonb_array_length(p_words) > 500 then
    raise exception 'Un vocabulario admite como máximo 500 palabras' using errcode = '54000';
  end if;

  if p_id is null then
    insert into public.vocabularies (title)
    values (coalesce(btrim(p_title), ''))
    returning id into v_id;
  else
    update public.vocabularies
       set title = coalesce(btrim(p_title), '')
     where id = p_id
    returning id into v_id;

    -- RLS oculta los vocabularios ajenos: no se distingue "no existe" de "no es tuyo".
    if v_id is null then
      raise exception 'Vocabulario no encontrado' using errcode = 'P0002';
    end if;

    delete from public.vocabulary_words where vocabulary_id = v_id;
  end if;

  insert into public.vocabulary_words (vocabulary_id, position, english, spanish, phonetic)
  select v_id,
         (t.ord - 1)::integer,
         btrim(t.w ->> 'english'),
         btrim(t.w ->> 'spanish'),
         coalesce(btrim(t.w ->> 'phonetic'), '')
    from jsonb_array_elements(p_words) with ordinality as t(w, ord);

  return v_id;
end;
$$;

revoke execute on function public.save_vocabulary(uuid, text, jsonb) from public, anon;
grant execute on function public.save_vocabulary(uuid, text, jsonb) to authenticated;
