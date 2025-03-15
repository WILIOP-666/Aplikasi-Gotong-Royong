import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gotong_royong/services/auth_service.dart';
import 'package:gotong_royong/services/event_service.dart';
import 'package:gotong_royong/screens/add_task_screen.dart';
import 'package:gotong_royong/screens/photo_gallery_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isAddingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _joinEvent() async {
    setState(() {
      _isJoining = true;
    });

    final eventService = Provider.of<EventService>(context, listen: false);
    final success = await eventService.joinEvent(widget.event['id']);

    setState(() {
      _isJoining = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join event')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined event')),
      );
    }
  }

  Future<void> _leaveEvent() async {
    setState(() {
      _isLeaving = true;
    });

    final eventService = Provider.of<EventService>(context, listen: false);
    final success = await eventService.leaveEvent(widget.event['id']);

    setState(() {
      _isLeaving = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to leave event')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully left event')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isAddingPhoto = true;
      });

      final eventService = Provider.of<EventService>(context, listen: false);
      final success = await eventService.addPhotoToEvent(
        widget.event['id'],
        File(image.path),
      );

      setState(() {
        _isAddingPhoto = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add photo')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isAddingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final eventService = Provider.of<EventService>(context);
    final currentUserId = authService.user?.uid;
    final isCreator = widget.event['creatorId'] == currentUserId;
    final isParticipant = (widget.event['participants'] as List).contains(currentUserId);
    final tasks = List<Map<String, dynamic>>.from(widget.event['tasks'] ?? []);
    final photoUrls = List<String>.from(widget.event['photoUrls'] ?? []);
    final eventDate = (widget.event['date'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['title']),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Tasks'),
            Tab(text: 'Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy - HH:mm').format(eventDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              widget.event['location'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event['description'] ?? 'No description provided',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Organized by',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event['creatorName'] ?? 'Anonymous',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(widget.event['participants'] as List).length} people joined',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        if (!isParticipant)
                          ElevatedButton(
                            onPressed: _isJoining ? null : _joinEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: _isJoining
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Join Event'),
                          )
                        else if (!isCreator)
                          ElevatedButton(
                            onPressed: _isLeaving ? null : _leaveEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLeaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Leave Event'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks Tab
          tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No tasks yet'),
                      const SizedBox(height: 16),
                      if (isParticipant)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTaskScreen(eventId: widget.event['id']),
                              ),
                            );
                          },
                          child: const Text('Add Task'),
                        ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ListView.builder(
                      itemCount: tasks.length,
                      padding: const EdgeInsets.all(16.0),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(
                              task['title'],
                              style: TextStyle(
                                decoration: task['completed'] == true
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(task['description'] ?? ''),
                            trailing: isParticipant
                                ? Checkbox(
                                    value: task['completed'] == true,
                                    onChanged: (value) {
                                      eventService.updateTaskStatus(
                                        widget.event['id'],
                                        task['id'],
                                        value ?? false,
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                    if (isParticipant)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTaskScreen(eventId: widget.event['id']),
                              ),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                ),
          
          // Photos Tab
          Stack(
            children: [
              photoUrls.isEmpty
                  ? const Center(child: Text('No photos yet'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photoUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotoGalleryScreen(
                                  photoUrls: photoUrls,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: photoUrls[index],
                            child: CachedNetworkImage(
                              imageUrl: photoUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                    ),
              if (isParticipant)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _isAddingPhoto ? null : _addPhoto,
                    child: _isAddingPhoto
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.add_a_photo),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}