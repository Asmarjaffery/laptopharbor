import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dialogflow_service.dart';

// ================= COLORS =================
class AppColors {
  static const deepBlack = Color(0xFF0A0A0A);
  static const cardBlack = Color(0xFF1A1A1A);
  static const richGold = Color(0xFFCB9B51);
  static const lightGold = Color(0xFFF6E27A);
  static const shineGold = Color(0xFFF6E27A);
  static const softGold = Color(0xFFFAF0DC);
  static const primaryColor = richGold;
  static const secondaryColor = lightGold;
}

// ================= CHATBOT SCREEN =================
class ChatbotScreen extends StatefulWidget {
  final String? userImageUrl;
  final String userName;
  final bool isFullScreen;

  const ChatbotScreen({
    Key? key,
    this.userImageUrl,
    this.userName = 'User',
    this.isFullScreen = true,
  }) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final DialogflowService _dialogflowService = DialogflowService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeDialogflow();
  }

  Future<void> _initializeDialogflow() async {
    try {
      await _dialogflowService.init();
      setState(() {
        _isInitialized = true;
      });
      _animationController.forward();
      _addMessage('Hello ${widget.userName}! How can I assist you today?', false);
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
      _showError('Failed to initialize chatbot. Please check your credentials.');
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= INTELLIGENT MESSAGE HANDLER =================
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    if (!_isInitialized) {
      _showError('Chatbot is not ready yet. Please wait...');
      return;
    }

    final userMessage = message.trim();
    _messageController.clear();
    _addMessage(userMessage, true);

    setState(() {
      _isLoading = true;
    });

    try {
      final lowerInput = userMessage.toLowerCase();
      String? result;

      print('🔍 User Query: "$userMessage"');

      // 1️⃣ PRIORITY: Check Firebase searches first
      result = await _searchBrand(lowerInput);
      if (result != null) {
        print('✅ Brand search successful');
        _addMessage(result, false);
        setState(() => _isLoading = false);
        return;
      }

      result = await _searchCategory(lowerInput);
      if (result != null) {
        print('✅ Category search successful');
        _addMessage(result, false);
        setState(() => _isLoading = false);
        return;
      }

      result = await _searchByPrice(lowerInput);
      if (result != null) {
        print('✅ Price search successful');
        _addMessage(result, false);
        setState(() => _isLoading = false);
        return;
      }

      // 2️⃣ LAST RESORT: Use Dialogflow only if no Firebase match
      print('⚡ Using Dialogflow for response');
      String response = await _dialogflowService.getResponse(userMessage);
      _addMessage(response, false);

    } catch (e) {
      _addMessage('Sorry, something went wrong. Please try again.', false);
      if (kDebugMode) print('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 IMPROVED BRAND SEARCH (Smart Keyword Detection)
  Future<String?> _searchBrand(String input) async {
    try {
      print('🔍 Searching brands for: "$input"');
      
      // Fetch all brands
      final brandQuery = await FirebaseFirestore.instance
          .collection('brands')
          .get();

      print('📦 Found ${brandQuery.docs.length} brands in database');

      // Check if input contains any brand name
      for (var brandDoc in brandQuery.docs) {
        final brandNameLower = (brandDoc['name'] as String).toLowerCase().trim();
        final inputWords = input.toLowerCase().split(' ');
        
        print('🏷️ Checking brand: "$brandNameLower"');
        
        // Match exact brand name OR if input contains brand name as a word
        if (input.toLowerCase().contains(brandNameLower) || 
            inputWords.contains(brandNameLower) ||
            brandNameLower.contains(input.toLowerCase().trim())) {
          
          print('✅ Brand matched: $brandNameLower');
          
          final brandId = brandDoc.id;
          final brandName = brandDoc['name'];

          final productsQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('brandId', isEqualTo: brandId)
              // .where('approvedAt', isGreaterThan: Timestamp(0, 0)) // Commented out temporarily
              .limit(5)
              .get();

          print('📱 Found ${productsQuery.docs.length} products for $brandName');

          if (productsQuery.docs.isNotEmpty) {
            final productList = productsQuery.docs.map((doc) {
              final name = doc['name'] ?? 'Unknown Product';
              final price = doc['price'] ?? 0;
              return '• $name (Rs. $price)';
            }).join('\n');

            return '✅ Top $brandName Products:\n\n$productList';
          } else {
            return '❌ No products found for $brandName.';
          }
        }
      }
      
      print('❌ No brand match found');
    } catch (e) {
      print('❌ Brand search error: $e');
    }
    return null;
  }

  // 🔹 IMPROVED CATEGORY SEARCH (Smart Keyword Detection)
  Future<String?> _searchCategory(String input) async {
    try {
      print('🔍 Searching categories for: "$input"');
      
      final categoryQuery = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      print('📦 Found ${categoryQuery.docs.length} categories in database');

      for (var categoryDoc in categoryQuery.docs) {
        final categoryName = (categoryDoc['name'] as String).toLowerCase().trim();
        final description = (categoryDoc['description'] as String?)?.toLowerCase().trim() ?? '';
        
        print('🏷️ Checking category: "$categoryName"');
        
        // Smart keyword matching with multiple variations
        bool isMatch = _matchCategoryKeywords(input.toLowerCase(), categoryName, description);
        
        if (isMatch) {
          print('✅ Category matched: $categoryName');
          
          final categoryId = categoryDoc.id;
          final categoryDisplayName = categoryDoc['name'];

          final productsQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('categoryId', isEqualTo: categoryId)
              // .where('approvedAt', isGreaterThan: Timestamp(0, 0)) // Commented out temporarily
              .limit(5)
              .get();

          print('📱 Found ${productsQuery.docs.length} products in $categoryDisplayName');

          if (productsQuery.docs.isNotEmpty) {
            final productList = productsQuery.docs.map((doc) {
              final name = doc['name'] ?? 'Unknown Product';
              final price = doc['price'] ?? 0;
              return '• $name (Rs. $price)';
            }).join('\n');

            return '✅ Top products in "$categoryDisplayName":\n\n$productList';
          } else {
            return '❌ No products found in "$categoryDisplayName".';
          }
        }
      }
      
      print('❌ No category match found');
    } catch (e) {
      print('❌ Category search error: $e');
    }
    return null;
  }

  // 🔹 SMART CATEGORY KEYWORD MATCHER
  bool _matchCategoryKeywords(String input, String categoryName, String description) {
    // Category-specific keyword mappings
    final Map<String, List<String>> categoryKeywords = {
      'touchscreen laptops': ['touch', 'touchscreen', 'touch screen', 'touch laptop', 'touch wala'],
      'gaming laptops': ['gaming', 'game', 'games', 'gaming laptop', 'game laptop', 'gaming wala'],
      'business laptops': ['business', 'office', 'work', 'professional', 'business laptop', 'office laptop'],
      'ultrabooks': ['ultrabook', 'ultra', 'slim', 'thin', 'lightweight', 'patla'],
      'gaming ultrabooks': ['gaming ultrabook', 'thin gaming', 'slim gaming'],
    };

    // Check if input contains category name
    if (input.contains(categoryName)) return true;

    // Check if input contains keywords for this category
    if (categoryKeywords.containsKey(categoryName)) {
      for (String keyword in categoryKeywords[categoryName]!) {
        if (input.contains(keyword)) {
          print('   ✓ Keyword matched: "$keyword" for category "$categoryName"');
          return true;
        }
      }
    }

    // Check description
    if (description.isNotEmpty && input.contains(description)) return true;

    return false;
  }

  // 🔹 IMPROVED PRICE RANGE SEARCH
  Future<String?> _searchByPrice(String input) async {
    try {
      print('🔍 Searching by price for: "$input"');
      
      // Extract price from input (e.g., "under 1000", "below 500", "price 800")
      final pricePattern = RegExp(r'(\d+)');
      final match = pricePattern.firstMatch(input);
      
      if (match != null) {
        final priceValue = int.parse(match.group(1)!);
        
        print('💰 Extracted price: $priceValue');
        
        Query query = FirebaseFirestore.instance
            .collection('products');
            // .where('approvedAt', isGreaterThan: Timestamp(0, 0)); // Commented out temporarily

        if (input.contains('under') || input.contains('below') || input.contains('less')) {
          print('⬇️ Searching for products under $priceValue');
          query = query.where('price', isLessThanOrEqualTo: priceValue).limit(5);
        } else if (input.contains('above') || input.contains('more') || input.contains('greater')) {
          print('⬆️ Searching for products above $priceValue');
          query = query.where('price', isGreaterThanOrEqualTo: priceValue).limit(5);
        } else {
          // Exact price or near price range
          print('🎯 Searching for products around $priceValue');
          query = query
              .where('price', isGreaterThanOrEqualTo: priceValue - 100)
              .where('price', isLessThanOrEqualTo: priceValue + 100)
              .limit(5);
        }

        final productsQuery = await query.get();

        print('📱 Found ${productsQuery.docs.length} products in price range');

        if (productsQuery.docs.isNotEmpty) {
          final productList = productsQuery.docs.map((doc) {
            final name = doc['name'] ?? 'Unknown Product';
            final price = doc['price'] ?? 0;
            return '• $name (Rs. $price)';
          }).join('\n');

          return '✅ Products matching your price criteria:\n\n$productList';
        } else {
          return '❌ No products found in this price range.';
        }
      }
      
      print('❌ No price extracted from input');
    } catch (e) {
      print('❌ Price search error: $e');
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.richGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================= DATABASE TEST BUTTON (TEMPORARY) =================
  Future<void> _testDatabase() async {
    print('\n=== 🔍 DATABASE TEST STARTED ===\n');
    
    try {
      // Test Brands
      final brands = await FirebaseFirestore.instance.collection('brands').get();
      print('📦 BRANDS FOUND: ${brands.docs.length}');
      for (var doc in brands.docs) {
        print('   Brand ID: ${doc.id}');
        print('   Brand Name: ${doc['name']}');
        print('   ---');
      }
      
      print('\n');
      
      // Test Products
      final products = await FirebaseFirestore.instance
          .collection('products')
          .limit(10)
          .get();
      print('📱 PRODUCTS FOUND: ${products.docs.length}');
      for (var doc in products.docs) {
        print('   Product: ${doc['name']}');
        print('   BrandID: ${doc['brandId']}');
        print('   Price: ${doc['price']}');
        print('   Approved: ${doc['approvedAt']}');
        print('   ---');
      }
      
      print('\n=== ✅ DATABASE TEST COMPLETED ===\n');
      
      _showError('Check console for database details');
    } catch (e) {
      print('❌ Database test error: $e');
      _showError('Database test failed: $e');
    }
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.richGold, AppColors.lightGold],
                ),
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: AppColors.deepBlack, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Assistant',
                    style: TextStyle(
                        color: AppColors.softGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                if (_isInitialized)
                  Row(
                    children: const [
                      Icon(Icons.circle, color: AppColors.shineGold, size: 8),
                      SizedBox(width: 4),
                      Text('Online',
                          style: TextStyle(color: AppColors.lightGold, fontSize: 11))
                    ],
                  )
              ],
            )
          ],
        ),
        backgroundColor: AppColors.cardBlack,
        actions: [
          // 🔧 TEMPORARY TEST BUTTON
          IconButton(
            icon: Icon(Icons.bug_report, color: AppColors.richGold),
            onPressed: _testDatabase,
            tooltip: 'Test Database',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                            size: 64, 
                            color: AppColors.richGold.withOpacity(0.3)),
                        SizedBox(height: 16),
                        Text('Start Conversation', 
                            style: TextStyle(
                              color: AppColors.softGold,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            )),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: _messages[index],
                        userImageUrl: widget.userImageUrl,
                        userName: widget.userName,
                      );
                    },
                  ),
          ),
          if (_isLoading) 
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.richGold,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Searching...', 
                      style: TextStyle(
                        color: AppColors.softGold,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppColors.softGold),
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: AppColors.richGold),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.richGold, AppColors.lightGold],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _sendMessage(_messageController.text),
                icon: const Icon(Icons.send_rounded, color: AppColors.deepBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dialogflowService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// ================= MESSAGE MODEL =================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ================= CHAT BUBBLE =================
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String? userImageUrl;
  final String userName;

  const ChatBubble({
    Key? key,
    required this.message,
    this.userImageUrl,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.richGold, AppColors.lightGold],
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded, 
                color: AppColors.deepBlack,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.richGold : AppColors.cardBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: message.isUser ? Radius.circular(16) : Radius.circular(4),
                  bottomRight: message.isUser ? Radius.circular(4) : Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? AppColors.deepBlack : AppColors.softGold,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold,
              ),
              child: userImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        userImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_rounded, 
                            color: AppColors.deepBlack,
                            size: 18,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded, 
                      color: AppColors.deepBlack,
                      size: 18,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}