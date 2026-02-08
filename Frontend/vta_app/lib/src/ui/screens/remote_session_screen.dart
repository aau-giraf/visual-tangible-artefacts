// lib/src/ui/screens/remote_session_screen.dart

import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';


final _log = Logger('RemoteSessionScreen');
class RemoteSessionScreen extends StatefulWidget {
  static const String routeName = "/remote";

  const RemoteSessionScreen({super.key});

  @override
  State<RemoteSessionScreen> createState() => _RemoteSessionScreenState();
}

class _RemoteSessionScreenState extends State<RemoteSessionScreen> {
  Map<String, String> contacts = {}; // name -> userId
  List<User> users = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = "";

  final SignalRService _signalRService = SignalRService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _listenForOnlineStatusChanges();
  }

  /// Listen for online status changes from SignalR and refresh UI
  void _listenForOnlineStatusChanges() {
    _log.fine('[RemoteSessionScreen] Setting up online status listener');

    _signalRService.onUserOnlineStatusChanged = (userId, isOnline) {
      _log.fine('RemoteSessionScreen Status Change');
      _log.fine('User: $userId');
      _log.fine('IsOnline: $isOnline');
      _log.fine('Mounted: $mounted');

      if (mounted) {
        setState(() {
          _log.fine('[RemoteSessionScreen] UI rebuild triggered');
        });
      } else {
        _log.fine('[RemoteSessionScreen] Not mounted, skipping setState');
      }
    };

    _log.fine('[RemoteSessionScreen] Online status listener registered');
  }

  Future<void> _loadContacts() async {
    _log.fine('[RemoteSessionScreen] Loading contacts...');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = "Ikke logget ind";
        });
        return;
      }

      final fetchedUsers = await UserRepository().fetchRelatedContacts(token);

      if (fetchedUsers == null) {
        setState(() {
          isLoading = false;
          errorMessage = "Kunne ikke hente kontakter";
        });
        return;
      }

      // Convert users list to contacts map
      final Map<String, String> newContacts = {};
      for (var user in fetchedUsers) {
        final displayName =
            user.name?.isNotEmpty == true ? user.name! : user.username;
        newContacts[displayName] = user.id;
      }

      _log.fine('[RemoteSessionScreen] Loaded ${newContacts.length} contacts');

      setState(() {
        users = fetchedUsers;
        contacts = newContacts;
        isLoading = false;
      });

      // Print initial online status
      _log.fine('[RemoteSessionScreen] Initial online users:');
      for (var entry in contacts.entries) {
        final isOnline = _isUserOnline(entry.value);
        _log.fine(
            '  - ${entry.key} (${entry.value}): ${isOnline ? "ONLINE" : "OFFLINE"}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Fejl ved indlæsning af kontakter: $e";
      });
    }
  }

  /// Check if a user is online by their userId
  bool _isUserOnline(String userId) {
    final isOnline = _signalRService.isUserOnline(userId);
    // _log.fine('[RemoteSessionScreen] isUserOnline($userId) = $isOnline');
    return isOnline;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = contacts.keys
        .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fjernsession"),
        actions: [
          // Debug button to check online status
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              _log.fine('[RemoteSessionScreen] Manual refresh triggered');
              await _signalRService.refreshOnlineUsers();
              setState(() {});
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: "Søg kontakt…",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("Ingen kontakter fundet"))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final name = filtered[index];
                                final userId = contacts[name]!;
                                final isOnline = _isUserOnline(userId);

                                return ListTile(
                                  leading: Stack(
                                    children: [
                                      const CircleAvatar(
                                        child: Icon(Icons.person),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOnline
                                                ? Colors.green
                                                : Colors.grey,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(name),
                                  subtitle: Text(
                                    isOnline ? "Online" : "Offline",
                                    style: TextStyle(
                                      color:
                                          isOnline ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text("Start"),
                                    onPressed: isOnline
                                        ? () async {
                                            _log.fine(
                                                '[RemoteSessionScreen] Starting call to $name ($userId)');
                                            // Navigate to calling screen
                                            Navigator.pushNamed(
                                              context,
                                              '/calling',
                                              arguments: {
                                                'childId': userId,
                                                'childName': name,
                                              },
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _log.fine('[RemoteSessionScreen] dispose');
    super.dispose();
  }
}
