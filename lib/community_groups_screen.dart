import 'package:flutter/material.dart';

class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Habesha Entrepreneurs EU',
      'interest': 'Business & startups',
      'messages': <String>[
        'Welcome everyone. Share your business pitch in 2 lines.',
        'Anyone knows low-cost accounting tools in Germany?'
      ]
    },
    {
      'name': 'Diaspora Healthcare Network',
      'interest': 'Doctors, nurses, pharmacy',
      'messages': <String>['We are planning a volunteer health webinar this weekend.']
    },
  ];

  int _selectedGroup = 0;

  @override
  void dispose() {
    _groupNameController.dispose();
    _interestController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _createGroup() {
    final name = _groupNameController.text.trim();
    final interest = _interestController.text.trim();
    if (name.isEmpty || interest.isEmpty) return;

    setState(() {
      _groups.insert(0, {
        'name': name,
        'interest': interest,
        'messages': <String>['Group created. Introduce yourself to members.'],
      });
      _selectedGroup = 0;
      _groupNameController.clear();
      _interestController.clear();
    });
  }

  void _postMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      (_groups[_selectedGroup]['messages'] as List<String>).add(text);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeMessages = _groups[_selectedGroup]['messages'] as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Community Groups'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return _buildMobile(activeMessages);
            }
            return _buildDesktop(activeMessages);
          },
        ),
      ),
    );
  }

  Widget _buildMobile(List<String> activeMessages) {
    return Column(
      children: [
        _buildCreateGroupCard(),
        _buildGroupSelector(),
        Expanded(child: _buildMessages(activeMessages)),
        _buildComposer(),
      ],
    );
  }

  Widget _buildDesktop(List<String> activeMessages) {
    return Row(
      children: [
        SizedBox(
          width: 330,
          child: Column(
            children: [
              _buildCreateGroupCard(),
              _buildGroupSelector(),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildMessages(activeMessages)),
              _buildComposer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create Group',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Group Name',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _interestController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Interest / Profession',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: _createGroup,
              child: const Text('Create Community Group'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Expanded(
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final selected = index == _selectedGroup;
          return ListTile(
            tileColor: selected ? const Color(0xFF123425) : null,
            title: Text(group['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(group['interest'], style: const TextStyle(color: Colors.white54)),
            onTap: () => setState(() => _selectedGroup = index),
          );
        },
      ),
    );
  }

  Widget _buildMessages(List<String> activeMessages) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: activeMessages.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            activeMessages[index],
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final systemBottomInset = mediaQuery.padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        10,
        10,
        10,
        10 + (keyboardInset > 0 ? 0 : systemBottomInset),
      ),
      decoration: const BoxDecoration(color: Color(0xFF0E2E1E)),
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Write a group message...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _postMessage,
              icon: const Icon(Icons.send, color: Color(0xFFF59E0B)),
            )
          ],
        ),
      ),
    );
  }
}
