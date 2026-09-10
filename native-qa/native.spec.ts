import {test,expect} from '@playwright/test';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {mkdir,readdir,readFile,copyFile} from 'node:fs/promises';
import path from 'node:path';
const execute=promisify(execFile);
test('installed DIY System creates and persists a local system',async({},info)=>{
 const platform=info.project.name;const device=process.env[`DIY_NATIVE_${platform.toUpperCase()}_DEVICE`];test.skip(!device,'Installed native app required');
 const output=info.outputPath('maestro');await mkdir(output,{recursive:true});const date=new Date().toLocaleDateString('en-CA',{timeZone:'America/Sao_Paulo'});
 const result=await execute(process.env.DIY_MAESTRO_BIN??'maestro',['--device',device!,'test',platform==='ios'?'ios-flow.yaml':'flow.yaml','-e',`PLATFORM=${platform}`,'-e',`TEST_DATE=${date}`,'--test-output-dir',output,'--format','JUNIT','--output',path.join(output,'result.xml')],{cwd:process.cwd(),timeout:540000,maxBuffer:3000000,env:{...process.env,MAESTRO_CLI_NO_ANALYTICS:'1',MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED:'true'}}).catch(e=>{throw Error(`${e.message}\n${e.stdout??''}\n${e.stderr??''}\nArtifacts: ${output}`)});
 await info.attach('maestro',{body:result.stdout,contentType:'text/plain'});const files=await readdir(output,{recursive:true});
 const dest=path.resolve('../test-screenshots');await mkdir(dest,{recursive:true});for(const name of ['inicio','administrador','conversa','previa','cadastro','registro','historico','persistencia']){const filename=`diy-mobile-${platform}-${name}-${date}.png`;const matches=files.filter(f=>path.basename(f)===filename);expect(matches).toHaveLength(1);const source=path.join(output,matches[0]);expect((await readFile(source)).subarray(0,8).toString('hex')).toBe('89504e470d0a1a0a');await copyFile(source,path.join(dest,filename));}
});
