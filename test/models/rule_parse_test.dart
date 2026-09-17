import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:test/test.dart';

void main() {
  group('Rule.parse', () {
    test('treats MATCH as payload-less and omits empty content', () {
      final rule = Rule.parse('MATCH,DIRECT');
      expect(rule.ruleAction, RuleAction.MATCH);
      expect(rule.content, isNull);
      expect(rule.ruleTarget, 'DIRECT');
      expect(rule.rawValue, 'MATCH,DIRECT');
    });

    test('parses MATCH without a target', () {
      final rule = Rule.parse('MATCH');
      expect(rule.ruleAction, RuleAction.MATCH);
      expect(rule.realContent, isNull);
      expect(rule.rawValue, 'MATCH');
    });

    test('is case-insensitive for the action type', () {
      final rule = Rule.parse('domain-suffix,google.com,PROXY');
      expect(rule.ruleAction, RuleAction.DOMAIN_SUFFIX);
      expect(rule.content, 'google.com');
      expect(rule.ruleTarget, 'PROXY');
    });

    test('keeps comma payloads for AND/OR/NOT rules', () {
      final rule = Rule.parse(
        'AND,((DOMAIN,google.com),(DOMAIN,youtube.com)),DIRECT',
      );
      expect(rule.ruleAction, RuleAction.AND);
      expect(rule.content, '((DOMAIN,google.com),(DOMAIN,youtube.com))');
      expect(rule.ruleTarget, 'DIRECT');
      expect(
        rule.rawValue,
        'AND,((DOMAIN,google.com),(DOMAIN,youtube.com)),DIRECT',
      );
    });

    test('parses RULE-SET provider, target, and no-resolve', () {
      final rule = Rule.parse('RULE-SET,provider,PROXY,no-resolve');
      expect(rule.ruleAction, RuleAction.RULE_SET);
      expect(rule.ruleProvider, 'provider');
      expect(rule.content, isNull);
      expect(rule.ruleTarget, 'PROXY');
      expect(rule.noResolve, isTrue);
      expect(rule.rawValue, 'RULE-SET,provider,PROXY,no-resolve');
    });

    test('parses src and no-resolve params', () {
      final rule = Rule.parse('IP-CIDR,10.0.0.0/8,DIRECT,src,no-resolve');
      expect(rule.ruleAction, RuleAction.IP_CIDR);
      expect(rule.content, '10.0.0.0/8');
      expect(rule.ruleTarget, 'DIRECT');
      expect(rule.src, isTrue);
      expect(rule.noResolve, isTrue);
    });

    test('parses DOMAIN-WILDCARD and process wildcard actions', () {
      final domain = Rule.parse('DOMAIN-WILDCARD,*.example.com,DIRECT');
      expect(domain.ruleAction, RuleAction.DOMAIN_WILDCARD);
      expect(domain.content, '*.example.com');
      expect(domain.rawValue, 'DOMAIN-WILDCARD,*.example.com,DIRECT');

      final process = Rule.parse(
        'PROCESS-NAME-WILDCARD,chrome*,PROXY',
      );
      expect(process.ruleAction, RuleAction.PROCESS_NAME_WILDCARD);
      expect(process.content, 'chrome*');
    });
  });
}
