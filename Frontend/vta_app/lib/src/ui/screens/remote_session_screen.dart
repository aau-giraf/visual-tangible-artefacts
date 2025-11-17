import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';

class RemoteSessionScreen extends StatefulWidget {
  static const String routeName = "/remote";

  const RemoteSessionScreen({super.key});

  @override
  State<RemoteSessionScreen> createState() => _RemoteSessionScreenState();
}

class _RemoteSessionScreenState extends State<RemoteSessionScreen> {
  Map<String, String> contacts = {
    "Device 1": "35e42095-f30a-4e7a-a008-24eb2e261056",
    "Device 2": "5d97e1fa-05b7-4a5d-9bd2-1680876a07dd",
  };

  String searchQuery = "";
  ArtifactBoardController? _boardController;

  @override
  void initState() {
    super.initState();

    // Incoming call handler
    SignalRService().onSessionRequested = (fromUserId) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            title: const Text("Indgående opkald"),
            content: Text("Bruger $fromUserId vil starte en fjernsession."),
            actions: [
              TextButton(
                onPressed: () {
                  SignalRService().rejectSession(fromUserId);
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text("Afvis"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final sessionId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  await SignalRService().acceptSession(
                    sessionId,
                    fromUserId,
                    SignalRService().currentUserId!,
                  );
                },
                child: const Text("Accepter"),
              ),
            ],
          );
        },
      );
    };

    // When a session is accepted (both sides navigate)
    SignalRService().onSessionStarted = (sessionId) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        "/remote-board",
        arguments: sessionId,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = contacts.keys
        .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Fjernsession")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: "Søg kontakt…",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
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

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(name),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Start"),
                          onPressed: () async {
                            await SignalRService().requestSession(userId);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Ringer til $name…")),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
