import 'package:flutter/material.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSessionScreen extends StatefulWidget {
  static const String routeName = "/remote";

  const RemoteSessionScreen({super.key});

  @override
  State<RemoteSessionScreen> createState() => _RemoteSessionScreenState();
}

class _RemoteSessionScreenState extends State<RemoteSessionScreen> {
  Map<String, String> contacts = {};
  List<User> users = [];
  bool isLoading = true;
  String? errorMessage;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
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

      setState(() {
        users = fetchedUsers;
        contacts = newContacts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Fejl ved indlæsning af kontakter: $e";
      });
    }
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
