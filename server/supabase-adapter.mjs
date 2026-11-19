import { createClient } from '@supabase/supabase-js';

export function createSupabaseClient(url, key) {
  return createClient(url, key, {
    auth: { persistSession: false }
  });
}

export function createSupabaseAdapter(supabase) {
  return {
    prepare(sql) {
      return {
        bind(...args) {
          return {
            async first() {
              const res = await execute(supabase, sql, args);
              return res.results?.[0] || null;
            },
            async all() {
              return await execute(supabase, sql, args);
            },
            async run() {
              return await execute(supabase, sql, args);
            }
          };
        }
      };
    },
    async batch(statements) {
      const out = [];
      for (const s of statements) {
        out.push(await s.run());
      }
      return out;
    }
  };
}

async function execute(supabase, sql, args) {
  // 1. Session lookup with user & company join
  if (/FROM sessions s JOIN users u/i.test(sql)) {
    const [tokenHash, expiresAt] = args;
    const { data: sess } = await supabase
      .from('sessions')
      .select('user_id')
      .eq('token_hash', tokenHash)
      .gt('expires_at', expiresAt)
      .maybeSingle();

    if (!sess) return { results: [] };

    const { data: user } = await supabase
      .from('users')
      .select('*')
      .eq('id', sess.user_id)
      .maybeSingle();

    if (!user) return { results: [] };

    const { data: comp } = await supabase
      .from('companies')
      .select('name, join_code')
      .eq('id', user.company_id)
      .maybeSingle();

    return {
      results: [{
        ...user,
        company_name: comp?.name || '',
        join_code: comp?.join_code || ''
      }]
    };
  }

  // 2. Insert session
  if (/INSERT INTO sessions/i.test(sql)) {
    const [tokenHash, userId, expiresAt] = args;
    const { data, error } = await supabase
      .from('sessions')
      .insert({ token_hash: tokenHash, user_id: userId, expires_at: expiresAt });
    if (error) throw error;
    return { results: [], meta: { changes: 1 } };
  }

  // 3. User by email
  if (/SELECT id FROM users WHERE email=\?/i.test(sql)) {
    const [email] = args;
    const { data } = await supabase.from('users').select('id').eq('email', email).maybeSingle();
    return { results: data ? [data] : [] };
  }

  // 4. Company by join_code
  if (/SELECT \* FROM companies WHERE join_code=\?/i.test(sql)) {
    const [joinCode] = args;
    const { data } = await supabase.from('companies').select('*').eq('join_code', joinCode).maybeSingle();
    return { results: data ? [data] : [] };
  }

  // 5. Company by name_key
  if (/SELECT id FROM companies WHERE name_key=\?/i.test(sql)) {
    const [nameKey] = args;
    const { data } = await supabase.from('companies').select('id').eq('name_key', nameKey).maybeSingle();
    return { results: data ? [data] : [] };
  }

  // 6. Insert company
  if (/INSERT INTO companies/i.test(sql)) {
    const [id, name, nameKey, joinCode, createdAt] = args;
    const { data, error } = await supabase
      .from('companies')
      .insert({ id, name, name_key: nameKey, join_code: joinCode, created_at: createdAt });
    if (error) throw error;
    return { results: [], meta: { changes: 1 } };
  }

  // 7. Insert user
  if (/INSERT INTO users/i.test(sql)) {
    const [id, companyId, name, email, phone, passwordHash, salt, role, createdAt] = args;
    const { data, error } = await supabase
      .from('users')
      .insert({ id, company_id: companyId, name, email, phone, password_hash: passwordHash, salt, role, created_at: createdAt });
    if (error) throw error;
    return { results: [], meta: { changes: 1 } };
  }

  // 8. Select login attempts
  if (/SELECT count,since FROM login_attempts WHERE key=\?/i.test(sql)) {
    const [key] = args;
    const { data } = await supabase.from('login_attempts').select('count, since').eq('key', key).maybeSingle();
    return { results: data ? [data] : [] };
  }

  // 9. Upsert login attempts
  if (/INSERT INTO login_attempts/i.test(sql)) {
    const [key, now] = args;
    const { data: existing } = await supabase.from('login_attempts').select('count, since').eq('key', key).maybeSingle();
    let count = 1;
    let since = now;
    if (existing) {
      if (now - existing.since > 900000) {
        count = 1;
        since = now;
      } else {
        count = existing.count + 1;
        since = existing.since;
      }
    }
    const { error } = await supabase.from('login_attempts').upsert({ key, count, since });
    if (error) throw error;
    return { results: [], meta: { changes: 1 } };
  }

  // 10. User login lookup with company
  if (/SELECT u\.\*,c\.name AS company_name,c\.join_code FROM users u JOIN companies c/i.test(sql)) {
    const [email] = args;
    const { data: user } = await supabase.from('users').select('*').eq('email', email).maybeSingle();
    if (!user) return { results: [] };
    const { data: comp } = await supabase.from('companies').select('name, join_code').eq('id', user.company_id).maybeSingle();
    return {
      results: [{
        ...user,
        company_name: comp?.name || '',
        join_code: comp?.join_code || ''
      }]
    };
  }

  // 11. Delete login attempts
  if (/DELETE FROM login_attempts WHERE key=\?/i.test(sql)) {
    const [key] = args;
    await supabase.from('login_attempts').delete().eq('key', key);
    return { results: [] };
  }

  // 12. Delete session by token_hash
  if (/DELETE FROM sessions WHERE token_hash=\?/i.test(sql)) {
    const [tokenHash] = args;
    await supabase.from('sessions').delete().eq('token_hash', tokenHash);
    return { results: [] };
  }

  // 13. Team members
  if (/SELECT id,name,email,role FROM users WHERE company_id=\?/i.test(sql)) {
    const [companyId] = args;
    const { data } = await supabase.from('users').select('id, name, email, role').eq('company_id', companyId).order('created_at');
    return { results: data || [] };
  }

  // 14. Update profile
  if (/UPDATE users SET name=\?,phone=\? WHERE id=\? AND company_id=\?/i.test(sql)) {
    const [name, phone, id, companyId] = args;
    await supabase.from('users').update({ name, phone }).eq('id', id).eq('company_id', companyId);
    return { results: [] };
  }

  // 15. Update password
  if (/UPDATE users SET password_hash=\?,salt=\? WHERE id=\?/i.test(sql)) {
    const [passwordHash, salt, id] = args;
    await supabase.from('users').update({ password_hash: passwordHash, salt }).eq('id', id);
    return { results: [] };
  }

  // 16. Delete sessions by user_id
  if (/DELETE FROM sessions WHERE user_id=\?/i.test(sql)) {
    const [userId] = args;
    await supabase.from('sessions').delete().eq('user_id', userId);
    return { results: [] };
  }

  // 17. Select records
  if (/SELECT kind,id,data,revision FROM records WHERE company_id=\?/i.test(sql)) {
    const [companyId] = args;
    const { data } = await supabase.from('records').select('kind, id, data, revision').eq('company_id', companyId).order('updated_at').order('id');
    return { results: data || [] };
  }

  // 18. Insert record revision 0 (ON CONFLICT DO NOTHING RETURNING id,kind,revision)
  if (/INSERT INTO records/i.test(sql)) {
    const [companyId, kind, id, recordData, now] = args;
    // Check if exists
    const { data: existing } = await supabase.from('records').select('id').eq('company_id', companyId).eq('kind', kind).eq('id', id).maybeSingle();
    if (existing) {
      return { results: [] };
    }
    const { data, error } = await supabase.from('records').insert({
      company_id: companyId,
      kind,
      id,
      data: recordData,
      revision: 1,
      updated_at: now
    }).select('id, kind, revision');
    if (error) throw error;
    return { results: data || [] };
  }

  // 19. Update record with optimistic revision
  if (/UPDATE records SET data=\?/i.test(sql)) {
    const [recordData, now, companyId, kind, id, revision] = args;
    const { data, error } = await supabase.from('records').update({
      data: recordData,
      revision: revision + 1,
      updated_at: now
    }).eq('company_id', companyId).eq('kind', kind).eq('id', id).eq('revision', revision).select('id, kind, revision');
    if (error) throw error;
    return { results: data || [] };
  }

  throw new Error(`[Supabase Adapter] Query não mapeada: ${sql}`);
}
