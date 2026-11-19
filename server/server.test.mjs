import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync,readdirSync} from 'node:fs';
import worker from './index.js';

function database(){
 const sqlite=new DatabaseSync(':memory:');sqlite.exec('PRAGMA foreign_keys=ON');
 for(const f of readdirSync('drizzle').filter(f=>f.endsWith('.sql')))sqlite.exec(readFileSync('drizzle/'+f,'utf8'));
 const db={prepare(sql){return {bind(...args){return {async first(){return sqlite.prepare(sql).get(...args)||null;},async all(){return {results:sqlite.prepare(sql).all(...args)};},async run(){const stmt=sqlite.prepare(sql);if(/RETURNING/i.test(sql))return {results:stmt.all(...args)};return {results:[],meta:stmt.run(...args)};}};}};},async batch(statements){sqlite.exec('BEGIN');try{const out=[];for(const s of statements)out.push(await s.run());sqlite.exec('COMMIT');return out;}catch(e){sqlite.exec('ROLLBACK');throw e;}}};
 return {db,sqlite};
}
async function call(db,path,{data,cookie,origin}={}){
 const request=new Request('https://loadsecure.example/api/'+path,{method:data?'POST':'GET',headers:{...(data?{'Content-Type':'application/json'}:{}),...(cookie?{cookie}:{}),...(origin?{origin}:{})},...(data?{body:JSON.stringify(data)}:{})});
 const response=await worker.fetch(request,{DB:db});return {status:response.status,data:await response.json(),cookie:response.headers.get('set-cookie')?.split(';')[0]};
}
const signup=(email,companyName,joinCode)=>({name:email.split('@')[0],email,password:'senhaForte123',phone:'11999999999',terms:true,companyName,joinCode});

test('Teams share persistent records, companies are isolated, password authentication is enforced',async()=>{
 const {db,sqlite}=database();
 const admin=await call(db,'register',{data:signup('admin@a.com','Empresa A')});assert.equal(admin.status,200);assert.equal(admin.data.user.role,'admin');
 const other=await call(db,'register',{data:signup('admin@b.com','Empresa B')});assert.equal(other.status,200);
 const colleague=await call(db,'register',{data:signup('colega@a.com','',admin.data.user.joinCode)});assert.equal(colleague.status,200);assert.equal(colleague.data.user.companyId,admin.data.user.companyId);assert.equal(colleague.data.user.role,'member');assert.equal(colleague.data.user.joinCode,undefined);
 assert.equal((await call(db,'register',{data:signup('intruso@a.com','Empresa A')})).status,409);
 assert.equal((await call(db,'register',{data:signup('intruso@a.com','','INVALIDO')})).status,404);
 assert.equal((await call(db,'login',{data:{email:'admin@a.com',password:'errada'}})).status,401);
 assert.equal((await call(db,'state')).status,401);
 const saved=await call(db,'state',{cookie:admin.cookie,data:{changes:[{kind:'cargos',id:'cargo-1',revision:0,data:{name:'Carga compartilhada'}}]}});assert.equal(saved.status,200);
 const teamState=await call(db,'state',{cookie:colleague.cookie});assert.equal(teamState.data.records[0].data.name,'Carga compartilhada');
 assert.equal((await call(db,'state',{cookie:other.cookie})).data.records.length,0);
 assert.equal((await call(db,'state',{cookie:other.cookie,data:{companyId:admin.data.user.companyId,changes:[{kind:'cargos',id:'cargo-1',revision:1,data:{name:'Invasão'}}]}})).status,409);
 assert.equal((await call(db,'state',{cookie:admin.cookie})).data.records[0].data.name,'Carga compartilhada');
 assert.equal((await call(db,'state',{cookie:colleague.cookie,data:{changes:[{kind:'settings',id:'limits',revision:0,data:{limit:'5'}}]}})).status,403);
 assert.equal((await call(db,'team',{cookie:colleague.cookie})).status,403);
 assert.equal((await call(db,'team',{cookie:admin.cookie})).data.members.length,2);
 const changed=await call(db,'state',{cookie:colleague.cookie,data:{changes:[{kind:'cargos',id:'cargo-1',revision:1,data:{name:'Atualizada pelo colega'}}]}});assert.equal(changed.status,200);
 assert.equal((await call(db,'state',{cookie:admin.cookie,data:{changes:[{kind:'cargos',id:'cargo-1',revision:1,data:{name:'Versão antiga'}}]}})).status,409);
 assert.equal((await call(db,'state',{cookie:admin.cookie})).data.records[0].data.name,'Atualizada pelo colega');
 assert.equal((await call(db,'state',{cookie:admin.cookie,origin:'https://evil.example',data:{changes:[]}})).status,403);
 assert.notEqual(sqlite.prepare('SELECT password_hash FROM users WHERE email=?').get('admin@a.com').password_hash,'senhaForte123');
 await call(db,'logout',{cookie:admin.cookie,data:{}});assert.equal((await call(db,'me',{cookie:admin.cookie})).status,401);
 const again=await call(db,'login',{data:{email:'admin@a.com',password:'senhaForte123'}});assert.equal(again.status,200);assert.equal((await call(db,'state',{cookie:again.cookie})).data.records[0].data.name,'Atualizada pelo colega');
 const password=await call(db,'password',{cookie:again.cookie,data:{currentPassword:'senhaForte123',password:'senhaNova123'}});assert.equal(password.status,200);assert.equal((await call(db,'me',{cookie:again.cookie})).status,401);assert.equal((await call(db,'login',{data:{email:'admin@a.com',password:'senhaNova123'}})).status,200);
 sqlite.close();
});
