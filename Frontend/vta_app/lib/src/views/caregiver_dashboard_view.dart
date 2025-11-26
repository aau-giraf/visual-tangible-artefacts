import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/pairing.dart';
import 'package:vta_app/src/services/relation_service.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/ui/screens/remote_board_screen.dart';

class CaregiverDashboardView extends StatefulWidget {
  const CaregiverDashboardView({Key? key}) : super(key: key);

  static const routeName = '/caregiver_dashboard';

  @override
  State<CaregiverDashboardView> createState() => _CaregiverDashboardViewState();
}

class _CaregiverDashboardViewState extends State<CaregiverDashboardView> {
  final RelationService _relationService = GetIt.I.get<RelationService>();
  final UserInfo _userInfo = GetIt.I.get<UserInfo>();
  final SignalRService _signalRService = SignalRService();

  List<PairingDTO> _pairings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPairings();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    if (_userInfo.userId != null) {
      await _signalRService.connect(_userInfo.userId!);

      _signalRService.onSessionStarted = (sessionId, boardId) {
        if (mounted) {
          Navigator.pushNamed(context, RemoteBoardScreen.routeName,
              arguments: {'sessionId': sessionId, 'boardId': boardId});
        }
      };
    }
  }

  Future<void> _fetchPairings() async {
    if (_userInfo.userId == null) return;

    setState(() {
      _isLoading = true;
    });

    final pairings =
        await _relationService.getPairingsForCaregiver(_userInfo.userId!);

    if (mounted) {
      setState(() {
        _pairings = pairings ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _startCall(String childId) async {
    await _signalRService.requestSession(childId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling child...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pairings.isEmpty
              ? const Center(child: Text('No children connected.'))
              : ListView.builder(
                  itemCount: _pairings.length,
                  itemBuilder: (context, index) {
                    final pairing = _pairings[index];
                    return ListTile(
                      title: Text(pairing.child.name ?? pairing.child.username),
                      subtitle: Text('Username: ${pairing.child.username}'),
                      trailing: ElevatedButton(
                        onPressed: () => _startCall(pairing.childId),
                        child: const Text('Start Call'),
                      ),
                    );
                  },
                ),
    );
  }
}
