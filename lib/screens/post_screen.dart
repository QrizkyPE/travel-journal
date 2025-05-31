import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/travel_post.dart';
import 'package:uuid/uuid.dart';
import '../services/travel_post_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'map_location_screen.dart';
import '../widgets/custom_bottom_navbar.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String _selectedCategory = 'Traveling';
  final List<String> _categories = [
    'Traveling',
    'Nature',
    'Beach',
    'City',
    'Mountain',
    'Historical',
    'Adventure',
  ];

  File? _selectedImage;
  bool _isLoading = false;
  
  // Add location coordinates
  double? _latitude;
  double? _longitude;

  // Add a variable for the selected bottom tab
  int _selectedIndex = 1; // Calendar is selected by default

  @override
  void dispose() {
    _placeNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: textColor),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day - 7);
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    '${_selectedDay.day} ${_getMonthName(_selectedDay.month)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: textColor),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day + 7);
                    });
                  },
                ),
              ],
            ),
            
            // Calendar
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red),
                  outsideDaysVisible: false,
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                headerVisible: false,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Category dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text('Kategori'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _categories.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Place name field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _placeNameController,
                decoration: const InputDecoration(
                  hintText: 'Nama Tempat',
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Tulis Pesan',
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload image button
            ElevatedButton(
              onPressed: () {
                _pickImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: containerColor,
                foregroundColor: Colors.black54,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image),
                  const SizedBox(width: 8),
                  Text(_selectedImage == null ? 'Masukan Gambar' : 'Gambar Dipilih'),
                  if (_selectedImage != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ],
              ),
            ),
            
            // Show selected image preview
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Location field with map button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      readOnly: true, // Make it read-only since we're using the map
                      decoration: const InputDecoration(
                        hintText: 'Masukan Lokasi',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _selectLocation(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Add button
            ElevatedButton(
              onPressed: () {
                _savePost();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Tambah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
  
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
  
  // Select location from map
  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const MapLocationScreen()),
    );
    
    if (result != null) {
      setState(() {
        _locationController.text = result['address'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }
  
  void _savePost() async {
    if (_placeNameController.text.isEmpty) {
      _showSnackBar('Nama tempat tidak boleh kosong');
      return;
    }
    
    if (_locationController.text.isEmpty) {
      _showSnackBar('Lokasi tidak boleh kosong');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final postId = const Uuid().v4();
      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        try {
          imageUrl = await travelPostService.uploadImage(_selectedImage!, postId);
          if (imageUrl == null) {
            // Handle failed upload but continue with post creation
            print('Image upload failed, continuing without image');
          }
        } catch (e) {
          print('Error uploading image: $e');
          // Continue without image if upload fails
        }
      }
      
      // Create a post using our model
      final post = TravelPost(
        id: postId,
        title: _placeNameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _locationController.text,
        imageUrl: imageUrl,
        date: _selectedDay,
        userId: 'current_user_id', // Will be replaced by the service
        latitude: _latitude,
        longitude: _longitude,
      );
      
      // Save to Firestore
      await travelPostService.addPost(post);
      
      if (mounted) {
        _showSnackBar('Post berhasil ditambahkan');
        _resetForm();
        
        // Navigate back to home screen after successful post creation
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _resetForm() {
    _placeNameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    setState(() {
      _selectedCategory = _categories[0];
      _selectedImage = null;
      _latitude = null;
      _longitude = null;
    });
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
} 