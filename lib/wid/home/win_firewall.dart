import 'package:dudulan/wid/home_box.dart';
import 'package:flutter/material.dart';
import 'package:dudulan/src/rust/api/firewall.dart';

class WinFirewall extends StatefulWidget {
  const WinFirewall({super.key});

  @override
  State<WinFirewall> createState() => _WinFirewallState();
}

class _WinFirewallState extends State<WinFirewall> {
  bool _isBatchLoading = false;
  final Map<String, bool> _firewallStatus = {
    'Domain': false,
    'Private': false,
    'Public': false,
  };

  final Map<String, int> _profileIndex = {
    'Domain': 1,
    'Private': 2,
    'Public': 3,
  };

  final Set<String> _individualLoading = {};

  @override
  void initState() {
    super.initState();
    _checkFirewallStatus();
  }

  Future<void> _checkFirewallStatus() async {
    try {
      final domain = await getFirewallStatus(profileIndex: 1);
      final private = await getFirewallStatus(profileIndex: 2);
      final public = await getFirewallStatus(profileIndex: 3);
      setState(() {
        _firewallStatus['Domain'] = domain;
        _firewallStatus['Private'] = private;
        _firewallStatus['Public'] = public;
      });
    } catch (e) {
      debugPrint('Error checking firewall status: $e');
    }
  }

  Future<void> _toggleFirewall(String profile, bool enable) async {
    setState(() => _individualLoading.add(profile));
    try {
      final idx = _profileIndex[profile]!;
      await setFirewallStatus(profileIndex: idx, enable: enable);
      setState(() => _firewallStatus[profile] = enable);
    } catch (e) {
      debugPrint('Error toggling firewall: $e');
    } finally {
      setState(() => _individualLoading.remove(profile));
    }
  }

  Future<void> _toggleAllFirewalls(bool enable) async {
    setState(() {
      _isBatchLoading = true;
      _individualLoading.addAll(_profileIndex.keys);
    });
    try {
      for (final profile in _profileIndex.keys) {
        final idx = _profileIndex[profile]!;
        await setFirewallStatus(profileIndex: idx, enable: enable);
        setState(() => _firewallStatus[profile] = enable);
      }
    } catch (e) {
      debugPrint('Error batch toggling firewall: $e');
    } finally {
      setState(() {
        _isBatchLoading = false;
        _individualLoading.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeBox(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Windows 防火墙',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBatchButtons(colorScheme),
          const SizedBox(height: 8),
          Column(
            children: _firewallStatus.entries.map((entry) =>
              _buildFirewallStatus(entry.key, entry.value, colorScheme)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        TextButton(
          onPressed: (_isBatchLoading)
              ? null
              : () => _toggleAllFirewalls(true),
          child: const Text('全部开启'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: (_isBatchLoading)
              ? null
              : () => _toggleAllFirewalls(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('全部关闭'),
        ),
      ],
    );
  }

  Widget _buildFirewallStatus(String profile, bool isEnabled, ColorScheme colorScheme) {
    final isLoading = _individualLoading.contains(profile);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: isEnabled ? colorScheme.primary : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$profile 防火墙',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEnabled ? colorScheme.secondaryContainer : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isEnabled ? '已启用' : '已禁用',
              style: TextStyle(
                color: isEnabled ? colorScheme.onSecondaryContainer : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(width: 12),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: _isBatchLoading
                      ? null
                      : () => _toggleFirewall(profile, !isEnabled),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled ? Colors.red.shade50 : colorScheme.primaryContainer,
                    foregroundColor: isEnabled ? Colors.red : colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isEnabled ? '关闭' : '开启'),
                ),
        ],
      ),
    );
  }
}
