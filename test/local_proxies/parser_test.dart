import 'dart:convert';

import 'package:fl_clash/local_proxies/services/local_proxy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = LocalProxyParser();

  group('ss:// URI parsing', () {
    test('parses ss://BASE64(method:password@server:port)#name', () {
      const uri =
          'ss://YWVzLTI1Ni1nY206cGFzc3dvcmQxMjM=@192.168.1.1:8388#Local%20SS';
      final results = parser.parseMany(uri);
      expect(results.length, 1);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'ss');
      expect(proxy.name, 'Local SS');
      expect(proxy.config['server'], '192.168.1.1');
      expect(proxy.config['port'], 8388);
      expect(proxy.config['cipher'], 'aes-256-gcm');
      expect(proxy.config['password'], 'password123');
      expect(proxy.config['udp'], true);
    });

    test('parses ss://BASE64(userinfo)@server:port', () {
      const uri = 'ss://YWVzLTEyOC1nY206cHdk@example.com:443';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['cipher'], 'aes-128-gcm');
      expect(proxy.config['password'], 'pwd');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
    });

    test('reports invalid SS without password', () {
      const uri = 'ss://YWVzLTI1Ni1nY20=@example.com:443';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNotNull);
    });
  });

  group('vless:// URI parsing', () {
    test('parses vless with tls and sni', () {
      const uri =
          'vless://uuid-123@example.com:443?security=tls&sni=cdn.example.com#VLESS%20Node';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'vless');
      expect(proxy.name, 'VLESS Node');
      expect(proxy.config['uuid'], 'uuid-123');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['tls'], true);
      expect(proxy.config['servername'], 'cdn.example.com');
      expect(proxy.config['network'], 'tcp');
      expect(proxy.config['udp'], true);
    });

    test('warns about non-tcp transport', () {
      const uri = 'vless://uuid@example.com:443?type=ws#WS';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      expect(results.first.warnings, isNotEmpty);
      expect(results.first.proxy!.config['network'], 'ws');
    });
  });

  group('trojan:// URI parsing', () {
    test('parses trojan with tls and allowInsecure', () {
      const uri =
          'trojan://pwd123@example.com:443?sni=cdn.example.com&allowInsecure=1#Trojan';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'trojan');
      expect(proxy.name, 'Trojan');
      expect(proxy.config['password'], 'pwd123');
      expect(proxy.config['sni'], 'cdn.example.com');
      expect(proxy.config['skip-cert-verify'], true);
      expect(proxy.config['udp'], true);
    });
  });

  group('anytls:// URI parsing', () {
    test('parses anytls with password, sni and fingerprint', () {
      const uri =
          'anytls://user:pass123@example.com:443?sni=cdn.example.com&hpkp=chrome&insecure=1#AnyTLS%20Node';
      final results = parser.parseMany(uri);
      expect(results.length, 1);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'anytls');
      expect(proxy.name, 'AnyTLS Node');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['password'], 'pass123');
      expect(proxy.config['sni'], 'cdn.example.com');
      expect(proxy.config['fingerprint'], 'chrome');
      expect(proxy.config['skip-cert-verify'], true);
      expect(proxy.config['udp'], true);
    });

    test('parses anytls without port using default 443', () {
      const uri = 'anytls://secret@example.com#Name';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['port'], 443);
      expect(proxy.config['password'], 'secret');
    });

    test('parses anytls alpn and ech', () {
      const uri =
          'anytls://secret@example.com:8443?alpn=h2,h3&ech=echconfig123';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['alpn'], ['h2', 'h3']);
      expect(proxy.config['ech-opts'], {
        'enable': true,
        'config': 'echconfig123',
      });
    });

    test('reports anytls without password', () {
      const uri = 'anytls://example.com:443#Name';
      final results = parser.parseMany(uri);
      expect(results.first.proxy, isNull);
      expect(results.first.error, isNotNull);
    });
  });

  group('nowhere:// URI parsing', () {
    test('parses nowhere with key, carriers and spec', () {
      const uri =
          'nowhere://secretkey@example.com:2077?up=tcp&down=tcp&spec=auto&sni=cdn.example.com&alpn=h2&pool=3&insecure=1&fp=chrome#Nowhere';
      final results = parser.parseMany(uri);
      expect(results.length, 1);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'nowhere');
      expect(proxy.name, 'Nowhere');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 2077);
      expect(proxy.config['key'], 'secretkey');
      expect(proxy.config['up'], 'tcp');
      expect(proxy.config['down'], 'tcp');
      expect(proxy.config['network'], 'tcp');
      expect(proxy.config['spec'], 'auto');
      expect(proxy.config['sni'], 'cdn.example.com');
      expect(proxy.config['alpn'], ['h2']);
      expect(proxy.config['pool'], 3);
      expect(proxy.config['skip-cert-verify'], true);
      expect(proxy.config['fingerprint'], 'chrome');
      expect(proxy.config['udp'], true);
    });

    test('parses nowhere without carriers defaulting to udp', () {
      const uri = 'nowhere://key@example.com#NW';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['up'], 'udp');
      expect(proxy.config['down'], 'udp');
      expect(proxy.config['port'], 443);
    });

    test('rejects nowhere with password component', () {
      const uri = 'nowhere://user:pass@example.com:443#NW';
      final results = parser.parseMany(uri);
      expect(results.first.proxy, isNull);
      expect(results.first.error, isNotNull);
    });

    test('rejects nowhere with invalid carriers', () {
      const uri = 'nowhere://key@example.com:443?up=icmp#NW';
      final results = parser.parseMany(uri);
      expect(results.first.proxy, isNull);
      expect(results.first.error, isNotNull);
    });
  });

  group('vmess:// URI parsing', () {
    test('parses V2RayN base64 JSON link', () {
      final json = jsonEncode({
        'ps': 'VMess Node',
        'add': 'example.com',
        'port': '443',
        'id': 'uuid-123',
        'aid': '0',
        'net': 'ws',
        'type': 'none',
        'host': 'cdn.example.com',
        'path': '/path?ed=2048',
        'tls': 'tls',
        'sni': 'sni.example.com',
        'alpn': 'h2,http/1.1',
      });
      final b64 = base64UrlEncode(utf8.encode(json));
      final uri = 'vmess://$b64';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'vmess');
      expect(proxy.name, 'VMess Node');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['uuid'], 'uuid-123');
      expect(proxy.config['tls'], true);
      expect(proxy.config['servername'], 'sni.example.com');
      expect(proxy.config['network'], 'ws');
      expect(proxy.config['alpn'], ['h2', 'http/1.1']);
      expect(proxy.config['ws-opts'], isA<Map>());
    });

    test('parses Xray VMessAEAD URI', () {
      const uri =
          'vmess://uuid-123@example.com:443?security=tls&type=ws&host=cdn.example.com&path=/ws&sni=sni.example.com#XrayVMess';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['uuid'], 'uuid-123');
      expect(proxy.config['tls'], true);
      expect(proxy.config['servername'], 'sni.example.com');
      expect(proxy.config['network'], 'ws');
      expect(proxy.config['client-fingerprint'], 'chrome');
    });
  });

  group('ssr:// URI parsing', () {
    test('parses ssr link', () {
      final inner =
          'example.com:8388:auth_aes128_md5:aes-256-cfb:http_simple:${_urlSafeBase64('pass123')}/?obfsparam=${_urlSafeBase64('obfs')}&protoparam=${_urlSafeBase64('proto')}&remarks=${_urlSafeBase64('SSR Node')}';
      final uri = 'ssr://${_urlSafeBase64(inner)}';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'ssr');
      expect(proxy.name, 'SSR Node');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], '8388');
      expect(proxy.config['cipher'], 'aes-256-cfb');
      expect(proxy.config['password'], 'pass123');
      expect(proxy.config['protocol'], 'auth_aes128_md5');
      expect(proxy.config['obfs'], 'http_simple');
      expect(proxy.config['obfs-param'], 'obfs');
      expect(proxy.config['protocol-param'], 'proto');
    });
  });

  group('hysteria:// URI parsing', () {
    test('parses hysteria link', () {
      const uri =
          'hysteria://example.com:443?peer=sni.example.com&auth=token&up=100&down=200&insecure=1&alpn=h3#Hysteria';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'hysteria');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['sni'], 'sni.example.com');
      expect(proxy.config['auth_str'], 'token');
      expect(proxy.config['up'], '100');
      expect(proxy.config['down'], '200');
      expect(proxy.config['skip-cert-verify'], true);
      expect(proxy.config['alpn'], ['h3']);
    });
  });

  group('hysteria2:// / hy2:// URI parsing', () {
    test('parses hysteria2 link', () {
      const uri =
          'hysteria2://password@example.com:443?sni=sni.example.com&obfs=salamander&obfs-password=obfspass&insecure=1&alpn=h3&pinSHA256=sha256#HY2';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'hysteria2');
      expect(proxy.config['password'], 'password');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['sni'], 'sni.example.com');
      expect(proxy.config['obfs'], 'salamander');
      expect(proxy.config['obfs-password'], 'obfspass');
      expect(proxy.config['fingerprint'], 'sha256');
      expect(proxy.config['skip-cert-verify'], true);
      expect(proxy.config['alpn'], ['h3']);
    });

    test('parses hy2 alias', () {
      const uri = 'hy2://pass@example.com#Alias';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      expect(results.first.proxy!.type, 'hysteria2');
    });
  });

  group('tuic:// URI parsing', () {
    test('parses TUIC v5 uuid:password link', () {
      const uri =
          'tuic://uuid-123:password@example.com:443?congestion_control=bbr&sni=sni.example.com&alpn=h3&udp_relay_mode=native#TUIC';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'tuic');
      expect(proxy.config['uuid'], 'uuid-123');
      expect(proxy.config['password'], 'password');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['congestion-controller'], 'bbr');
      expect(proxy.config['sni'], 'sni.example.com');
      expect(proxy.config['alpn'], ['h3']);
      expect(proxy.config['udp-relay-mode'], 'native');
    });

    test('parses TUIC v4 token link', () {
      const uri = 'tuic://token@example.com:443#TUIC4';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.config['token'], 'token');
      expect(proxy.config.containsKey('uuid'), false);
    });
  });

  group('socks5:// / http:// / https:// URI parsing', () {
    test('parses socks5 with base64 userinfo', () {
      final userInfo = base64Encode(utf8.encode('user:pass'));
      final uri = 'socks5://$userInfo@example.com:1080#SOCKS';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'socks5');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 1080);
      expect(proxy.config['username'], 'user');
      expect(proxy.config['password'], 'pass');
    });

    test('parses http with plain userinfo', () {
      const uri = 'http://user:pass@example.com:8080#HTTP';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'http');
      expect(proxy.config['username'], 'user');
      expect(proxy.config['password'], 'pass');
    });

    test('parses https with tls flag', () {
      const uri = 'https://example.com:8443#HTTPS';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'http');
      expect(proxy.config['tls'], true);
    });
  });

  group('mierus:// URI parsing', () {
    test('parses mierus link', () {
      const uri =
          'mierus://user:pass@example.com?port=443&protocol=TCP&multiplexing=1&handshake-mode=paranoid&traffic-pattern=random#Mieru';
      final results = parser.parseMany(uri);
      expect(results.first.error, isNull);
      final proxy = results.first.proxy!;
      expect(proxy.type, 'mieru');
      expect(proxy.config['server'], 'example.com');
      expect(proxy.config['port'], 443);
      expect(proxy.config['transport'], 'TCP');
      expect(proxy.config['username'], 'user');
      expect(proxy.config['password'], 'pass');
      expect(proxy.config['multiplexing'], '1');
    });
  });

  group('multi-line and partial import', () {
    test('good nodes imported and bad node reported', () {
      const text = '''
ss://YWVzLTI1Ni1nY206cGFzc0AxLjIuMy40OjEyMzQ=#Good
invalid://example.com
ss://bad#Bad
''';
      final results = parser.parseMany(text);
      expect(results.length, 3);
      expect(results[0].proxy, isNotNull);
      expect(results[1].proxy, isNull);
      expect(results[2].proxy, isNull);
    });
  });
}

String _urlSafeBase64(String input) {
  return base64UrlEncode(utf8.encode(input));
}
