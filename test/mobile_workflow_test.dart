import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:diy_system/src/app_controller.dart';
import 'package:diy_system/src/services/app_store.dart';
import 'package:diy_system/src/services/gateway_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('mobile session saves a generated record and requires login after restart', () async {
    final directory = await Directory.systemTemp.createTemp('diy-mobile-unit-');
    addTearDown(() => directory.delete(recursive: true));
    final gateway = GatewayClient(client: MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      expect(body['auth']['installationId'], isNotEmpty);
      final entitlement = {'kind':'trial','tier':'mini','daysRemaining':7};
      return http.Response(jsonEncode(request.url.path.endsWith('/status') ? {'entitlement':entitlement} : {
        'message':'Cadastro pronto', 'ready':true, 'entitlement':entitlement,
        'manifest':{'schemaVersion':1,'revision':1,'name':'Oficina Demo','purpose':'Cadastro de clientes ficticios','screens':[
          {'id':'clientes','title':'Clientes','description':'Teste','singularLabel':'Cliente','fields':[
            {'id':'nome','label':'Nome','type':'text','required':true}
          ]}
        ]}
      }),200);
    }));
    final controller = AppController(store:await AppStore.open(directory:directory),gateway:gateway);
    await controller.initialize();
    await controller.createAdmin(name:'Ana Demo',email:'ana@example.invalid',password:'demonstracao123',confirmation:'demonstracao123');
    expect(controller.phase,AppPhase.studio);
    await controller.sendAnswer('Quero cadastrar clientes');
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.openSystem();
    expect(controller.phase, AppPhase.system);
    expect(notifications, 1);
    controller.openStudio();
    expect(controller.phase, AppPhase.studio);
    expect(notifications, 2);
    await controller.createRecord('clientes',{'nome':'Cliente Demo','intruso':'nao salvar'});
    expect(controller.error,isNull);
    expect(controller.state.records['clientes']!.single.values,{'nome':'Cliente Demo'});
    await controller.logout();
    expect(controller.authenticated,isFalse);
    final reopened=AppController(store:await AppStore.open(directory:directory),gateway:gateway);
    await reopened.initialize();
    expect(reopened.phase,AppPhase.login);
    await reopened.login('ana@example.invalid','senha errada');
    expect(reopened.authenticated,isFalse);
    await reopened.login('ana@example.invalid','demonstracao123');
    expect(reopened.phase,AppPhase.system);
    expect(reopened.state.records['clientes']!.single.values['nome'],'Cliente Demo');
    expect(reopened.state.audit.map((e)=>e.action),containsAll(['admin.created','system.created','record.created','admin.logout','admin.login']));
  });
}
