import 'package:flutter/material.dart';
import 'package:apptobe/core/widgets/common_widgets.dart';
import 'package:apptobe/core/constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search',
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            AppTextField(
              label: 'Search',
              controller: _searchController,
              hintText: 'Enter your search query...',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
            const SizedBox(height: AppConstants.defaultSpacing),
            Expanded(
              child: Center(
                child: Text(
                  'Search functionality coming soon',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}