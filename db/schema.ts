import { sqliteTable, text, integer, primaryKey, uniqueIndex, index } from 'drizzle-orm/sqlite-core';
export const companies = sqliteTable('companies', {
 id: text('id').primaryKey(), name: text('name').notNull(), nameKey: text('name_key').notNull(), joinCode: text('join_code').notNull(), createdAt: integer('created_at').notNull()
}, t => [uniqueIndex('companies_name_key').on(t.nameKey), uniqueIndex('companies_join_code').on(t.joinCode)]);
export const users = sqliteTable('users', {
 id:text('id').primaryKey(), companyId:text('company_id').notNull().references(()=>companies.id), name:text('name').notNull(), email:text('email').notNull(), phone:text('phone').notNull().default(''), passwordHash:text('password_hash').notNull(), salt:text('salt').notNull(), role:text('role').notNull(), createdAt:integer('created_at').notNull()
},t=>[uniqueIndex('users_email').on(t.email),index('users_company').on(t.companyId)]);
export const sessions = sqliteTable('sessions', {
 tokenHash:text('token_hash').primaryKey(), userId:text('user_id').notNull().references(()=>users.id), expiresAt:integer('expires_at').notNull()
});
export const records=sqliteTable('records', {
 companyId:text('company_id').notNull().references(()=>companies.id), kind:text('kind').notNull(), id:text('id').notNull(), data:text('data').notNull(), revision:integer('revision').notNull(), updatedAt:integer('updated_at').notNull()
},t=>[primaryKey({columns:[t.companyId,t.kind,t.id]})]);
export const loginAttempts=sqliteTable('login_attempts',{
 key:text('key').primaryKey(), count:integer('count').notNull(), since:integer('since').notNull()
});
