import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class AdvancedFilterView extends StatefulWidget {
  final SortOption initialSortBy;
  final Set<String> initialCategoryIds;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final List<CategoryModel> availableCategories;
  final Function({
    required SortOption newSortBy,
    required Set<String> newCategoryIds,
    double? newMinPrice,
    double? newMaxPrice,
  })
  onApplyFilters;

  final bool showCategoryFilter;
  const AdvancedFilterView({
    super.key,
    required this.initialSortBy,
    required this.initialCategoryIds,
    this.initialMinPrice,
    this.initialMaxPrice,
    required this.onApplyFilters,
    required this.availableCategories,
    this.showCategoryFilter = true,
  });
  @override
  State<AdvancedFilterView> createState() => _AdvancedFilterViewState();
}

class _AdvancedFilterViewState extends State<AdvancedFilterView> {
  late SortOption _selectedSortBy;
  late Set<String> _selectedCategoryIds;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.initialSortBy;
    _selectedCategoryIds = {...widget.initialCategoryIds};
    _minPriceController = TextEditingController(
      text: widget.initialMinPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onApply() {
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);
    widget.onApplyFilters(
      newSortBy: _selectedSortBy,
      newCategoryIds: _selectedCategoryIds,
      newMinPrice: minPrice,
      newMaxPrice: maxPrice,
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters & Sort'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSortBy = SortOption.dateDesc;
                if (widget.showCategoryFilter) {
                  _selectedCategoryIds.clear();
                }
                _minPriceController.clear();
                _maxPriceController.clear();
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<SortOption>(
              value: _selectedSortBy,
              items: SortOption.values
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedSortBy = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            Text('Price Range', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),

            Visibility(
              visible: widget.showCategoryFilter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: widget.availableCategories.map((category) {
                      final isSelected = _selectedCategoryIds.contains(
                        category.id,
                      );
                      return FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _onApply,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Apply Filters'),
        ),
      ),
    );
  }
}
