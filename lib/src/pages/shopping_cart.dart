import 'package:app/src/utilities/context.dart';
import 'package:app/src/utilities/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:app/src/components/item_card.dart'; // Adjust the import path as necessary

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  _ShoppingCartState createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  final TextEditingController _changeController = TextEditingController();
  bool _showFirstRow = true; // State variable to toggle rows
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadItems(); // Load items from the database
  }

  Future<void> _loadItems() async {
    final items = await _databaseHelper.getCartItems();
    print('Loaded items from DB CART: $items');
    setState(() {
      allItems = List<Map<String, dynamic>>.from(items);  // Ensure mutability
      filteredItems = List<Map<String, dynamic>>.from(items)..sort((a, b) => a['checked'].compareTo(b['checked']));  // Ensure mutability
    });
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = allItems
          .where((item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredItems.sort((a, b) => a['checked'].compareTo(b['checked']));
    });
  }

  Future<void> _updateItem(int index, String name, String quantity, String price) async {
    final id = filteredItems[index]['id'];
    final updatedItem = {'name': name, 'quantity': quantity, 'price': price};

    await _databaseHelper.updateItem(id, updatedItem);
    await _loadItems(); // Reload items to refresh UI
  }

  void _removeFromCart(int id) async {
    await _databaseHelper.removeFromCart(id); // Delete from database
    await _loadItems();
  }

  void _changeCheck(int id, int check) async {
    if (check == 1){
      await _databaseHelper.uncheckItem(id);
    } else {
      await _databaseHelper.checkItem(id);
    }
    await _loadItems();
  }


  double _calculateExpectedTotal() {
    double total = 0.0;
    for (final item in allItems) {
      final quantity = double.tryParse(item['quantity'] ?? '') ?? 0;
      final price = double.tryParse(item['price'] ?? '') ?? 0;
      total += quantity * price;
    }
    return total;
  }

  double _calculateTotal() {
    double total = 0.0;
    for (final item in allItems) {
      // Check if the item is checked
      if (item['checked'] == 1) {
        final quantity = double.tryParse(item['quantity'] ?? '') ?? 0;
        final price = double.tryParse(item['price'] ?? '') ?? 0;
        total += quantity * price;
      }
    }
    return total;
  }

  double _calculateMultiplierValue(double total) {
    final multiplier = double.tryParse(_changeController.text) ?? 0;
    return total * multiplier;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Items',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterItems, // Call filter function on text change
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  key: ValueKey(filteredItems[index]['name']), // Unique key for each card
                  itemName: filteredItems[index]['name'],
                  quantity: filteredItems[index]['quantity'],
                  price: filteredItems[index]['price'],
                  state: filteredItems[index]['state'], 
                  checked: filteredItems[index]['checked'] == 1 ? true: false,
                  context: ItemCardContext.cart, 
                  onItemChanged: (name, quantity, price) {
                    _updateItem(index, name, quantity, price);
                  },
                    onDeleteItem: () {
                  }, 
                  onChangeState: () {  
                    _removeFromCart(filteredItems[index]['id']);
                  }, 
                  onCheckItem: () {  
                    _changeCheck(filteredItems[index]['id'], filteredItems[index]['checked'] );
                  },
                ); // Display the ItemCard for each filtered item
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Button to toggle rows
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showFirstRow = !_showFirstRow; // Toggle the boolean state
                    });
                  },
                  child: const Icon(Icons.currency_exchange),
                ),
              ),
              if (_showFirstRow)
              Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top:8.0),
                      child: Text(
                        'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Expected: \$${_calculateExpectedTotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              // Conditionally show the second row
              if (!_showFirstRow)
              Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top:8.0),
                      child: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _changeController,
                          decoration: const InputDecoration(
                            labelText: '1\$ = Bs',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) => setState(() {}), // Update UI on change
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Total Bs. ${_calculateMultiplierValue(_calculateTotal()).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
