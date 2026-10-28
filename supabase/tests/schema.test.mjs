// Pruebas del esquema contra un PostgreSQL real (PGlite, sin Docker).
// Emula lo que Supabase aporta: roles anon/authenticated, auth.users y auth.uid().
import { PGlite } from '@electric-sql/pglite';
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

// Aplica todas las migraciones de supabase/migrations, en orden.
const migrationsDir = fileURLToPath(new URL('../migrations/', import.meta.url));
const migration = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort()
  .map((f) => readFileSync(join(migrationsDir, f), 'utf8'))
  .join('\n');

const db = new PGlite();

// --- Emulación mínima de Supabase: roles, auth.users, auth.uid() y privilegios por defecto.
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  create table auth.users (id uuid primary key default gen_random_uuid(), email text);
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
  $$;
  grant usage on schema public, auth to anon, authenticated, service_role;
  grant execute on function auth.uid() to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
`);

let passed = 0;
let failed = 0;
function check(name, ok, extra = '') {
  if (ok) { passed++; console.log(`  ok   ${name}`); }
  else { failed++; console.log(`  FAIL ${name} ${extra}`); }
}

async function run(role, userId, sql, params = []) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${userId ?? ''}', false); set role ${role};`);
  try { return { rows: (await db.query(sql, params)).rows }; }
  catch (e) { return { error: e }; }
  finally { await db.exec('reset role'); }
}
const asUser = (id, sql, p) => run('authenticated', id, sql, p);
const asAnon = (sql, p) => run('anon', null, sql, p);

// --- 1. La migración se aplica sin errores.
await db.exec(migration);
check('la migración se aplica completa', true);

const [A, B] = ['11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'];
await db.exec(`insert into auth.users (id, email) values ('${A}','a@x.com'), ('${B}','b@x.com')`);

const words = JSON.stringify([
  { english: 'Egg', spanish: 'Huevo', phonetic: 'eg' },
  { english: 'Sun', spanish: 'Sol' },
  { english: ' Lamb ', spanish: ' Cordero ', phonetic: '' },
]);
const save = (u, id, title, w = words) =>
  asUser(u, 'select public.save_vocabulary($1::uuid, $2, $3::jsonb) as id', [id, title, w]);

console.log('\nGuardado');
const created = await save(A, null, '  Pascua  ');
check('crea un vocabulario y devuelve su id', !created.error && /^[0-9a-f-]{36}$/.test(created.rows?.[0]?.id), created.error?.message);
const vocA = created.rows[0].id;

let r = await asUser(A, 'select title, user_id from public.vocabularies');
check('el título se guarda sin espacios sobrantes', r.rows[0]?.title === 'Pascua');
check('user_id se completa con auth.uid()', r.rows[0]?.user_id === A);

r = await asUser(A, 'select position, english, spanish, phonetic from public.vocabulary_words order by position');
check('guarda 3 palabras con posiciones 0,1,2', r.rows.map((x) => x.position).join() === '0,1,2');
check('respeta el orden del arreglo', r.rows.map((x) => x.english).join() === 'Egg,Sun,Lamb');
check('recorta espacios y la fonética vacía queda como ""', r.rows[2].spanish === 'Cordero' && r.rows[1].phonetic === '');

const upd = await save(A, vocA, 'Pascua 2026', JSON.stringify([{ english: 'Bunny', spanish: 'Conejito' }]));
check('actualizar devuelve el mismo id', upd.rows?.[0]?.id === vocA, upd.error?.message);
r = await asUser(A, 'select english, position from public.vocabulary_words');
check('actualizar reemplaza las palabras (no duplica)', r.rows.length === 1 && r.rows[0].english === 'Bunny' && r.rows[0].position === 0);
r = await asUser(A, 'select count(*)::int n, bool_and(updated_at >= created_at) ok from public.vocabularies');
check('hay un solo vocabulario tras actualizar', r.rows[0].n === 1 && r.rows[0].ok === true);

console.log('\nAislamiento entre usuarios (RLS)');
r = await asUser(B, 'select count(*)::int n from public.vocabularies');
check('B no ve los vocabularios de A', r.rows[0].n === 0);
r = await asUser(B, 'select count(*)::int n from public.vocabulary_words');
check('B no ve las palabras de A', r.rows[0].n === 0);
r = await save(B, vocA, 'hackeado');
check('B no puede sobrescribir el vocabulario de A con save_vocabulary (P0002)', r.error?.code === 'P0002', r.error?.message);
r = await asUser(B, `update public.vocabularies set title = 'x' where id = '${vocA}' returning id`);
check('B no puede modificar filas de A (0 filas)', !r.error && r.rows.length === 0);
r = await asUser(B, `delete from public.vocabularies where id = '${vocA}' returning id`);
check('B no puede borrar filas de A (0 filas)', !r.error && r.rows.length === 0);
r = await asUser(B, `insert into public.vocabulary_words (vocabulary_id, position, english, spanish) values ('${vocA}', 5, 'a', 'b')`);
check('B no puede colgar palabras del vocabulario de A (FK compuesta)', r.error?.code === '23503', r.error?.message);
r = await asUser(B, `insert into public.vocabulary_words (vocabulary_id, user_id, position, english, spanish) values ('${vocA}', '${A}', 5, 'a', 'b')`);
check('B no puede insertar fingiendo ser A (RLS WITH CHECK)', r.error?.code === '42501', r.error?.message);
r = await asUser(B, `insert into public.vocabularies (user_id, title) values ('${A}', 'x')`);
check('B no puede crear vocabularios a nombre de A', r.error?.code === '42501', r.error?.message);
r = await asUser(A, 'select count(*)::int n from public.vocabularies');
check('los datos de A siguen intactos', r.rows[0].n === 1);

console.log('\nVisitantes sin sesión');
r = await asAnon('select * from public.vocabularies');
check('anon no puede leer vocabularios', r.error?.code === '42501', r.error?.message);
r = await asAnon('select * from public.vocabulary_words');
check('anon no puede leer palabras', r.error?.code === '42501', r.error?.message);
r = await asAnon(`select public.save_vocabulary(null, 'x', '[]'::jsonb)`);
check('anon no puede ejecutar save_vocabulary', r.error?.code === '42501', r.error?.message);
r = await run('authenticated', '', `select public.save_vocabulary(null, 'x', '[]'::jsonb)`);
check('sin uid válido save_vocabulary falla (28000)', r.error?.code === '28000', r.error?.message);

console.log('\nValidaciones');
r = await save(A, null, 'x'.repeat(121), '[]');
check('título de 121 caracteres rechazado', r.error?.code === '23514', r.error?.message);
r = await save(A, null, 'x'.repeat(120), '[]');
check('título de 120 caracteres aceptado', !r.error, r.error?.message);
r = await save(A, null, null, '[]');
check('título null se guarda como ""', !r.error);
r = await save(A, null, 't', JSON.stringify([{ english: '   ', spanish: 'x' }]));
check('palabra en inglés vacía rechazada', r.error?.code === '23514', r.error?.message);
r = await save(A, null, 't', JSON.stringify([{ english: 'x', spanish: 'y'.repeat(121) }]));
check('traducción de 121 caracteres rechazada', r.error?.code === '23514', r.error?.message);
r = await save(A, null, 't', '{"a":1}');
check('p_words que no es arreglo rechazado (22023)', r.error?.code === '22023', r.error?.message);
r = await save(A, null, 't', JSON.stringify(Array.from({ length: 501 }, (_, i) => ({ english: `e${i}`, spanish: `s${i}` }))));
check('501 palabras rechazadas (54000)', r.error?.code === '54000', r.error?.message);
r = await save(A, null, 't', JSON.stringify(Array.from({ length: 500 }, (_, i) => ({ english: `e${i}`, spanish: `s${i}` }))));
check('500 palabras aceptadas', !r.error, r.error?.message);
r = await asUser(A, `select count(*)::int n from public.vocabularies where title = 't' `);
// Un guardado fallido no debe dejar un vocabulario a medias (la función es atómica por ser una sola sentencia).
check('un guardado fallido no deja filas huérfanas', r.rows[0].n === 1, `n=${r.rows[0].n}`);

console.log('\nLímite de vocabularios por usuario');
await db.exec(`reset role; delete from public.vocabularies where user_id = '${B}'`);
for (let i = 0; i < 100; i++) {
  const x = await save(B, null, `v${i}`, '[]');
  if (x.error) { check(`creación ${i + 1} de 100`, false, x.error.message); break; }
}
r = await asUser(B, 'select count(*)::int n from public.vocabularies');
check('B puede tener 100 vocabularios', r.rows[0].n === 100);
r = await save(B, null, 'uno más', '[]');
check('el vocabulario 101 se rechaza (54000)', r.error?.code === '54000', r.error?.message);

console.log('\nBorrado en cascada');
r = await asUser(A, `delete from public.vocabularies where id = '${vocA}' returning id`);
check('A puede borrar su vocabulario', r.rows.length === 1);
await db.exec('reset role');
r = await db.query(`select count(*)::int n from public.vocabulary_words where vocabulary_id = '${vocA}'`);
check('se borran sus palabras en cascada', r.rows[0].n === 0);
await db.exec(`delete from auth.users where id = '${B}'`);
r = await db.query(`select count(*)::int n from public.vocabularies where user_id = '${B}'`);
check('al borrar un usuario se borran sus vocabularios', r.rows[0].n === 0);

console.log('\nEstructura');
r = await db.query(`select relname, relrowsecurity from pg_class where relname in ('vocabularies','vocabulary_words') order by 1`);
check('RLS activado en ambas tablas', r.rows.length === 2 && r.rows.every((x) => x.relrowsecurity));
r = await db.query(`select count(*)::int n from pg_policies where schemaname='public'`);
check('8 políticas (4 por tabla)', r.rows[0].n === 8, `n=${r.rows[0].n}`);
r = await db.query(`select has_table_privilege('anon','public.vocabularies','select') a, has_table_privilege('authenticated','public.vocabularies','select') b`);
check('anon sin privilegios y authenticated con privilegios', r.rows[0].a === false && r.rows[0].b === true);

console.log(`\n${passed} correctas, ${failed} fallidas`);
process.exit(failed ? 1 : 0);
