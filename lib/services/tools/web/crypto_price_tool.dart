import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../tool_registry.dart';

/// Fetches the current price of a cryptocurrency using the CoinGecko
/// free API (no API key required).
class CryptoPriceTool extends Tool {
  @override
  String get name => 'crypto_price';

  @override
  String get displayName => 'Crypto Price';

  @override
  String get statusLabel => 'Fetching crypto price…';

  @override
  String get description =>
      'Get the current price of a cryptocurrency in USD. '
      'Use this when the user asks about the price of Bitcoin, Ethereum, '
      'or any other cryptocurrency.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'coin_id': {
            'type': 'string',
            'description':
                'The CoinGecko coin ID, e.g. "bitcoin", "ethereum", "solana", '
                    '"dogecoin". Use lowercase. For common tickers: '
                    'BTC=bitcoin, ETH=ethereum, SOL=solana, DOGE=dogecoin, '
                    'BNB=binancecoin, XRP=ripple, ADA=cardano, AVAX=avalanche-2, '
                    'DOT=polkadot, MATIC=matic-network, LINK=chainlink, '
                    'UNI=uniswap, LTC=litecoin.',
          },
        },
        'required': ['coin_id'],
      };

  @override
  IconData get icon => Icons.currency_bitcoin;

  @override
  bool get enabledByDefault => true;

  @override
  Future<String> execute(String argumentsJson) async {
    final args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    final coinId = (args['coin_id'] as String?)?.toLowerCase() ?? 'bitcoin';

    final errors = <String>[];
    // Try Binance first (fast, CN-accessible via api.binance.com), then
    // OKX, then CoinGecko as last resort.
    final symbol = _coinIdToBinanceSymbol(coinId);
    if (symbol != null) {
      final r = await _tryBinance(coinId, symbol, errors);
      if (r != null) return r;
      final o = await _tryOkx(coinId, symbol, errors);
      if (o != null) return o;
    }
    final g = await _tryCoinGecko(coinId, errors);
    if (g != null) return g;
    return jsonEncode({'error': 'All price sources failed: ${errors.join(" | ")}'});
  }

  Future<String?> _tryBinance(
      String coinId, String symbol, List<String> errors) async {
    try {
      final uri = Uri.parse(
          'https://api.binance.com/api/v3/ticker/24hr?symbol=${symbol}USDT');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        errors.add('binance:${resp.statusCode}');
        return null;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return jsonEncode({
        'coin': coinId,
        'source': 'binance',
        'price_usd': double.tryParse('${j['lastPrice']}'),
        'change_24h_percent': double.tryParse('${j['priceChangePercent']}'),
      });
    } catch (e) {
      errors.add('binance:$e');
      return null;
    }
  }

  Future<String?> _tryOkx(
      String coinId, String symbol, List<String> errors) async {
    try {
      final uri = Uri.parse(
          'https://www.okx.com/api/v5/market/ticker?instId=$symbol-USDT');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) {
        errors.add('okx:${resp.statusCode}');
        return null;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = (j['data'] as List?)?.firstOrNull as Map?;
      if (data == null) {
        errors.add('okx:no-data');
        return null;
      }
      final last = double.tryParse('${data['last']}');
      final open24 = double.tryParse('${data['open24h']}');
      double? change;
      if (last != null && open24 != null && open24 != 0) {
        change = (last - open24) / open24 * 100;
      }
      return jsonEncode({
        'coin': coinId,
        'source': 'okx',
        'price_usd': last,
        'change_24h_percent': change,
      });
    } catch (e) {
      errors.add('okx:$e');
      return null;
    }
  }

  Future<String?> _tryCoinGecko(String coinId, List<String> errors) async {
    try {
      final uri = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=$coinId&vs_currencies=usd&include_24hr_change=true'
        '&include_market_cap=true',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        errors.add('coingecko:${resp.statusCode}');
        return null;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final coin = data[coinId];
      if (coin == null) {
        errors.add('coingecko:not-found');
        return null;
      }
      return jsonEncode({
        'coin': coinId,
        'source': 'coingecko',
        'price_usd': coin['usd'],
        'change_24h_percent': coin['usd_24h_change'],
        'market_cap_usd': coin['usd_market_cap'],
      });
    } catch (e) {
      errors.add('coingecko:$e');
      return null;
    }
  }

  static String? _coinIdToBinanceSymbol(String coinId) {
    const map = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'solana': 'SOL',
      'dogecoin': 'DOGE',
      'binancecoin': 'BNB',
      'ripple': 'XRP',
      'cardano': 'ADA',
      'avalanche-2': 'AVAX',
      'polkadot': 'DOT',
      'matic-network': 'MATIC',
      'chainlink': 'LINK',
      'uniswap': 'UNI',
      'litecoin': 'LTC',
    };
    return map[coinId];
  }
}
