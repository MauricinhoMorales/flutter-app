import 'package:app/src/utilities/context.dart';
import 'package:app/src/utilities/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:app/src/components/item_card.dart'; // Adjust the import path as necessary

class ShoppingStorage extends StatefulWidget {
  const ShoppingStorage({super.key});

  @override
  _ShoppingStorageState createState() => _ShoppingStorageState();
}

class _ShoppingStorageState extends State<ShoppingStorage> {
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
    final items = await _databaseHelper.getItems();
    print('Loaded items from DB STORAGE: $items');
    setState(() {
      allItems = List<Map<String, dynamic>>.from(items);  // Ensure mutability
      filteredItems = List<Map<String, dynamic>>.from(items)
        ..sort((a, b) {
          if (a['state'] == 'storage' && b['state'] != 'storage') {
            return -1; // Put 'storage' items at the top
          } else if (a['state'] != 'storage' && b['state'] == 'storage') {
            return 1;  // Put 'non-storage' items below
          } else {
            return 0;  // Keep order the same if states are equal
          }
        });
    });
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = allItems
          .where((item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort((a, b) {
          if (a['state'] == 'storage' && b['state'] != 'storage') {
            return -1; // Put 'storage' items at the top
          } else if (a['state'] != 'storage' && b['state'] == 'storage') {
            return 1;  // Put 'non-storage' items below
          } else {
            return 0;  // Keep order the same if states are equal
          }
        });
    });
  }


  Future<void> _updateItem(int index, String name, String quantity, String price) async {
    final id = filteredItems[index]['id'];
    final updatedItem = {'name': name, 'quantity': quantity, 'price': price};

    await _databaseHelper.updateItem(id, updatedItem);
    await _loadItems(); // Reload items to refresh UI
  }

  Future<void> _addItem(String name, String quantity, String price) async {
    final newItem = {
      'name': name,
      'quantity': quantity,
      'price': price,
      'state': 'storage',
      'checked': 0
    };
    await _databaseHelper.insertItem(newItem);
    await _loadItems(); // Reload items to reflect the new addition
  }

  void _deleteItem(int id, String itemName) async {
    bool confirmed = await _showDeleteConfirmationDialog(id, itemName);
    
    if (confirmed) {
      await _databaseHelper.deleteItem(id); // Delete from database
      await _loadItems(); // Reload the items after deletion
    }
  }

  void _changeState(int id, String state) async {
      if (state == 'cart') {
        await _databaseHelper.removeFromCart(id);  // Update the database to remove from cart
      } else {
        await _showQuantityDialog(context, id, state);
      }
      await _loadItems();  // Reload the items to refresh the UI
  }

  Future<bool> _showDeleteConfirmationDialog(int id, String itemName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $itemName?'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels the deletion
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms the deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false); // Return false if dialog is dismissed without selecting an option
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap the button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final name = nameController.text;
                final price = priceController.text;

                if (name.isNotEmpty && price.isNotEmpty) {
                  await _addItem(name, '0', price); // Add the item to the database
                  Navigator.of(context).pop(); // Dismiss the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQuantityDialog(BuildContext context, int id, String state) async {
    final TextEditingController quantityController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap the button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Quantity'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                final quantity = quantityController.text;

                if (quantity.isNotEmpty) {
                  await _databaseHelper.addToCart(id);  // Update the database to add to cart
                  // Optionally, you can update the quantity in the database here as well
                  await _databaseHelper.updateItem(id, {'quantity': quantity});
                  Navigator.of(context).pop(); // Return the quantity
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a quantity')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
                  context: ItemCardContext.storage, 
                  onItemChanged: (name, quantity, price) {
                    _updateItem(index, name, quantity, price);
                  },
                    onDeleteItem: () {
                    _deleteItem(filteredItems[index]['id'],filteredItems[index]['name']); // Pass the delete function
                  },  
                  onChangeState: () {  
                    _changeState(filteredItems[index]['id'], filteredItems[index]['state']);
                  },
                  onCheckItem: () {}, 
                ); // Display the ItemCard for each filtered item
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top:8.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddItemDialog(context); // Show the dialog to add a new item
              },
              child: const Text('Add Item'),
            ),
          )
        ],
      ),
    );
  }
}
