import http from 'node:http';
const entitlement={kind:'trial',tier:'mini',daysRemaining:7};
const server=http.createServer(async(req,res)=>{
 if(req.method!=='POST'||!['/api/license/status','/api/agent/turn'].includes(req.url)){res.writeHead(404);res.end();return;}
 let text='';for await(const chunk of req){text+=chunk;if(text.length>200000){res.writeHead(413);res.end();return;}}
 let body;try{body=JSON.parse(text);}catch{res.writeHead(400);res.end();return;}
 if(!/^[a-f0-9]{32}$/.test(body.auth?.installationId??'')){res.writeHead(401);res.end();return;}
 const manifest={schemaVersion:1,revision:(body.manifest?.revision??0)+1,name:'Oficina Demo',purpose:'Cadastro local de clientes ficticios para testar o aplicativo.',screens:[{id:'clientes',title:'Clientes',description:'Cadastros de demonstracao',singularLabel:'Cliente',fields:[{id:'nome',label:'Nome do cliente',type:'text',required:true},{id:'telefone',label:'Telefone',type:'phone',required:false}]}]};
 const payload=req.url==='/api/license/status'?{entitlement}:{message:'Sistema de demonstracao pronto. Abra o cadastro de clientes.',ready:true,manifest,entitlement};res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify(payload));console.log(req.url===' /api/license/status'?'status':req.url,'local fixture request');
});server.listen(8787,'127.0.0.1',()=>console.log('DIY local deterministic gateway on 127.0.0.1:8787; no external calls'));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close(()=>process.exit(0)));
